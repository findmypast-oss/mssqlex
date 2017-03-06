defmodule Mssqlex.Protocol do
  @moduledoc """
  Implementation of `DBConnection` behaviour for `Mssqlex.ODBC`.

  Handles translation of concepts to what ODBC expects and holds
  state for a connection.

  This module is not called directly, but rather through
  other `Mssqlex` modules or `DBConnection` functions.
  """

  use DBConnection

  alias Mssqlex.ODBC
  alias Mssqlex.Result

  defstruct [pid: nil, mssql: :idle, conn_opts: []]

  @typedoc """
  Process state.

  Includes:

  * `:pid`: the pid of the ODBC process
  * `:mssql`: the transaction state. Can be `:idle` (not in a transaction),
    `:transaction` (in a transaction) or `:auto_commit` (connection in
    autocommit mode)
  * `:conn_opts`: the options used to set up the connection.
  """
  @type state :: %__MODULE__{pid: pid(),
                             mssql: :idle | :transaction | :auto_commit,
                             conn_opts: Keyword.t}

  @type query :: Mssqlex.Query.t
  @type params :: [{:odbc.odbc_data_type(), :odbc.value()}]
  @type result :: Result.t
  @type cursor :: any

  @doc false
  @spec connect(opts :: Keyword.t) :: {:ok, state}
                                    | {:error, Exception.t}
  def connect(opts) do
    conn_opts = [
      {"DRIVER", opts[:odbc_driver]},
      {"SERVER", opts[:hostname]},
      {"DATABASE", opts[:database]},
      {"UID", opts[:username]},
      {"PWD", opts[:password]}
    ]
    conn_str = Enum.reduce(conn_opts, "", fn {key, value}, acc ->
      acc <> "#{key}=#{value};" end)

    case ODBC.start_link(conn_str, opts) do
      {:ok, pid} -> {:ok, %__MODULE__{
                        pid: pid,
                        conn_opts: opts,
                        mssql: if(opts[:auto_commit] == :on,
                          do: :auto_commit,
                          else: :idle)
                     }}
      response -> response
    end
  end

  @doc false
  @spec disconnect(err :: Exception.t, state) :: :ok
  def disconnect(_err, state = %{pid: pid}) do
    case ODBC.disconnect(pid) do
      :ok -> :ok
      {:error, reason} -> {:error, reason, state}
    end
  end

  @doc false
  @spec reconnect(new_opts :: Keyword.t, state) :: {:ok, state}
  def reconnect(new_opts, state) do
    with :ok <- disconnect("Reconnecting", state),
      do: connect(new_opts)
  end

  @doc false
  @spec checkout(state) :: {:ok, state}
                         | {:disconnect, Exception.t, state}
  def checkout(state) do
    {:ok, state}
  end

  @doc false
  @spec checkin(state) :: {:ok, state}
                        | {:disconnect, Exception.t, state}
  def checkin(state) do
    {:ok, state}
  end

  @doc false
  @spec handle_begin(opts :: Keyword.t, state) ::
    {:ok, result, state}
  | {:error | :disconnect, Exception.t, state}
  def handle_begin(_opts, state) do
    case state.mssql do
      :idle -> {:ok, %Result{num_rows: 0}, %{state | mssql: :transaction}}
      :transaction -> {:error,
        %Mssqlex.Error{message: "Already in transaction"},
        state}
      :auto_commit -> {:error,
        %Mssqlex.Error{message: "Transactions not allowed in autocommit mode"},
        state}
    end
  end

  @doc false
  @spec handle_commit(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_commit(_opts, state = %{pid: pid}) do
    case ODBC.commit(pid) do
      :ok -> {:ok, %Result{}, %{state | mssql: :idle}}
      {:error, reason} -> {:error, reason, state}
    end
  end

  @doc false
  @spec handle_rollback(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_rollback(_opts, state = %{pid: pid}) do
    case ODBC.rollback(pid) do
      :ok -> {:ok, %Result{}, %{state | mssql: :idle}}
      {:error, reason} -> {:disconnect, reason, state}
    end
  end

  @doc false
  @spec handle_prepare(query, opts :: Keyword.t, state) ::
    {:ok, query, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @doc false
  @spec handle_execute(query, params, opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_execute(query, params, opts, state) do
    {status, message, new_state} = do_query(query, params, opts, state)

    case new_state.mssql do
      :idle -> 
        with {:ok, _, post_commit_state} <- handle_commit(opts, new_state)
        do
          {status, message, post_commit_state}
        end
      :transaction -> {status, message, new_state}
      :auto_commit ->
        with {:ok, post_connect_state} <- switch_auto_commit(:off, new_state)
        do
          {status, message, post_connect_state}
        end
    end
  end

  defp do_query(query, params, opts, state) do
    case ODBC.query(state.pid, query.statement, params) do
      {:error,
        %Mssqlex.Error{odbc_code: :not_allowed_in_transaction} = reason} ->
        if state.mssql == :auto_commit do
          {:error, reason, state}
        else
          with {:ok, new_state} <- switch_auto_commit(:on, state),
            do: handle_execute(query, params, opts, new_state)
        end
      {:error, reason} ->
        {:error, reason, state}
      {:selected, _columns, rows} ->
        {:ok, %Result{rows: rows, num_rows: Enum.count(rows)}, state}
      {:updated, num_rows} ->
        {:ok, %Result{num_rows: num_rows}, state}
    end
  end

  defp switch_auto_commit(new_value, state) do
    reconnect(Keyword.put(state.conn_opts, :auto_commit, new_value), state)
  end

  @doc false
  @spec handle_close(query, opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_close(_query, _opts, state) do
    {:ok, %Result{}, state}
  end

  # @spec handle_declare(query, params, opts :: Keyword.t, state) ::
  #   {:ok, cursor, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_declare(_query, _params, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_first(query, cursor, opts :: Keyword.t, state) ::
  #   {:ok | :deallocate, result, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_first(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_next(query, cursor, opts :: Keyword.t, state) ::
  #   {:ok | :deallocate, result, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_next(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_deallocate(query, cursor, opts :: Keyword.t, state) ::
  #   {:ok, result, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_deallocate(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
end
