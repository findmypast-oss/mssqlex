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
  alias Mssqlex.Error

  defstruct [pid: nil, mssql: :idle]

  @type state :: %__MODULE__{pid: pid(), mssql: :idle | :transaction}

  @type query :: Mssqlex.Query.t
  @type params :: any
  @type result :: Result.t
  @type cursor :: any

  @spec connect(opts :: Keyword.t) ::
    {:ok, state} | {:error, Exception.t}
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

    case ODBC.start_link(conn_str, []) do
      {:ok, pid} -> {:ok, %__MODULE__{pid: pid}}
      response -> response
    end
  end

  @spec disconnect(err :: Exception.t, state) :: :ok
  def disconnect(_error, %{pid: pid}) do
    :odbc.disconnect(pid)
  end

  @spec checkout(state) ::
    {:ok, state} | {:disconnect, Exception.t, state}
  def checkout(state) do
    {:ok, state}
  end

  @spec checkin(state) ::
    {:ok, state} | {:disconnect, Exception.t, state}
  def checkin(state) do
    {:ok, state}
  end

  @spec handle_begin(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_begin(_opts, %{mssql: :transaction} = state) do
    {:error, %Error{message: "already in transaction"}, state}
  end

  def handle_begin(_opts, state) do
    {:ok, %Result{num_rows: 0}, Map.put(state, :mssql, :transaction)}
  end

  @spec handle_commit(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_commit(_opts, state) do
    ODBC.commit(state)
  end

  @spec handle_rollback(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_rollback(_opts, state) do
    ODBC.rollback(state)
  end

  @spec handle_prepare(query, opts :: Keyword.t, state) ::
    {:ok, query, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @spec handle_execute(query, params, opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_execute(query, _params, _opts, state) do
    response = case ODBC.query(state.pid, query.statement, []) do
      {:error, reason} ->
        {:error, reason, state}
      {:selected, _columns, rows} ->
        {:ok, %Result{rows: rows, num_rows: Enum.count(rows)}, state}
      {:updated, num_rows} ->
        {:ok, %Result{num_rows: num_rows}, state}
    end
    if state.mssql == :idle do
      with :ok <- ODBC.commit(state.pid),
      do: response
    else
      response
    end
  end

  # @spec handle_close(query, opts :: Keyword.t, state) ::
  #   {:ok, result, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_close(_query, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
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
