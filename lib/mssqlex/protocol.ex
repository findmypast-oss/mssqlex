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

  defstruct pid: nil, mssql: :idle, conn_opts: []

  @typedoc """
  Process state.

  Includes:

  * `:pid`: the pid of the ODBC process
  * `:mssql`: the transaction state. Can be `:idle` (not in a transaction),
    `:transaction` (in a transaction) or `:auto_commit` (connection in
    autocommit mode)
  * `:conn_opts`: the options used to set up the connection.
  """
  @type state :: %__MODULE__{
          pid: pid(),
          mssql: :idle | :transaction | :auto_commit,
          conn_opts: Keyword.t()
        }

  @type opts :: Keyword.t()
  @type query :: Mssqlex.Query.t()
  @type params :: [{:odbc.odbc_data_type(), :odbc.value()}]
  @type result :: Result.t()
  @type cursor :: any
  @type status :: :idle | :transaction | :error

  @doc false
  @spec connect(opts) :: {:ok, state} | {:error, Exception.t()}
  def connect(opts) do
    server_address =
      opts[:hostname] || System.get_env("MSSQL_HST") || "localhost"

    instance_name = opts[:instance_name] || System.get_env("MSSQL_IN")
    port = opts[:port] || System.get_env("MSSQL_PRT")
    encrypt = opts[:encrypt] || System.get_env("MSSQL_ENCRYPT")

    trust =
      opts[:trust_server_certificate] ||
        System.get_env("MSSQL_TRUST_SERVER_CERT")

    conn_opts = [
      {"Driver",
       opts[:odbc_driver] || System.get_env("MSSQL_DVR") ||
         "{ODBC Driver 17 for SQL Server}"},
      {"Server", build_server_address(server_address, instance_name, port)},
      {"Database", opts[:database] || System.get_env("MSSQL_DB")},
      {"UID", opts[:username] || System.get_env("MSSQL_UID")},
      {"PWD", opts[:password] || System.get_env("MSSQL_PWD")},
      {"Encrypt", to_yesno(encrypt)},
      {"TrustServerCertificate", to_yesno(trust)}
    ]

    conn_str =
      Enum.reduce(conn_opts, "", fn {key, value}, acc ->
        acc <> "#{key}=#{value};"
      end)

    {:ok, pid} = ODBC.start_link(conn_str, opts)

    {:ok,
     %__MODULE__{
       pid: pid,
       conn_opts: opts,
       mssql:
         if opts[:auto_commit] == :on do
           :auto_commit
         else
           :idle
         end
     }}
  end

  @spec build_server_address(String.t(), String.t(), String.t()) :: String.t()
  defp build_server_address(server_address, nil, nil), do: server_address

  defp build_server_address(server_address, instance_name, nil),
    do: "#{server_address}\\#{instance_name}"

  defp build_server_address(server_address, nil, port),
    do: "#{server_address},#{port}"

  defp build_server_address(server_address, instance_name, port),
    do: "#{server_address}\\#{instance_name},#{port}"

  defp to_yesno(value) when value in ["yes", true], do: "yes"
  defp to_yesno(value) when value in ["no", nil, false], do: "no"

  @doc false
  @spec disconnect(err :: Exception.t(), state) :: :ok
  def disconnect(_err, %{pid: pid} = _state) do
    :ok = ODBC.disconnect(pid)
  end

  @doc false
  @spec reconnect(opts, state) :: {:ok, state}
  def reconnect(new_opts, state) do
    disconnect("Reconnecting", state)
    connect(new_opts)
  end

  @doc false
  @spec checkout(state) ::
          {:ok, state}
          | {:disconnect, Exception.t(), state}
  def checkout(state) do
    {:ok, state}
  end

  @doc false
  @spec checkin(state) ::
          {:ok, state}
          | {:disconnect, Exception.t(), state}
  def checkin(state) do
    {:ok, state}
  end

  @doc false
  @spec handle_begin(opts, state) ::
          {:ok, result, state}
          | {status, state}
          | {:disconnect, Exception.t(), state}
  def handle_begin(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:begin, opts, state)
      :savepoint -> handle_savepoint(:begin, opts, state)
    end
    |> clean_result()
  end

  @doc false
  @spec handle_commit(opts, state) ::
          {:ok, result, state}
          | {status, state}
          | {:disconnect, Exception.t(), state}
  def handle_commit(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:commit, opts, state)
      :savepoint -> handle_savepoint(:commit, opts, state)
    end
    |> clean_result()
  end

  @doc false
  @spec handle_rollback(opts, state) ::
          {:ok, result(), state}
          | {status, state}
          | {:disconnect, Exception.t(), state}
  def handle_rollback(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:rollback, opts, state)
      :savepoint -> handle_savepoint(:rollback, opts, state)
    end
    |> clean_result()
  end

  defp clean_result(result) do
    case result do
      {:ok, _query, %Mssqlex.Result{} = result, %Mssqlex.Protocol{} = state} ->
        {:ok, result, state}

      result ->
        result
    end
  end

  defp handle_transaction(:begin, _opts, state) do
    case state.mssql do
      :idle ->
        {:ok, %Result{num_rows: 0}, %{state | mssql: :transaction}}

      :transaction ->
        {:error, %Mssqlex.Error{message: "Already in transaction"}, state}

      :auto_commit ->
        {:error,
         %Mssqlex.Error{message: "Transactions not allowed in autocommit mode"},
         state}
    end
  end

  defp handle_transaction(:commit, _opts, state) do
    case ODBC.commit(state.pid) do
      :ok -> {:ok, %Result{}, %{state | mssql: :idle}}
      {:error, reason} -> {:error, reason, state}
    end
  end

  defp handle_transaction(:rollback, _opts, state) do
    case ODBC.rollback(state.pid) do
      :ok -> {:ok, %Result{}, %{state | mssql: :idle}}
      {:error, reason} -> {:disconnect, reason, state}
    end
  end

  defp handle_savepoint(:begin, opts, state) do
    if state.mssql == :autocommit do
      {:error,
       %Mssqlex.Error{message: "savepoint not allowed in autocommit mode"},
       state}
    else
      handle_execute(
        %Mssqlex.Query{
          name: "",
          statement: "SAVE TRANSACTION mssqlex_savepoint"
        },
        [],
        opts,
        state
      )
    end
  end

  defp handle_savepoint(:commit, _opts, state) do
    {:ok, %Result{}, state}
  end

  defp handle_savepoint(:rollback, opts, state) do
    handle_execute(
      %Mssqlex.Query{
        name: "",
        statement: "ROLLBACK TRANSACTION mssqlex_savepoint"
      },
      [],
      opts,
      state
    )
  end

  @doc false
  @spec handle_prepare(query, opts, state) ::
          {:ok, query, state}
          | {:error | :disconnect, Exception.t(), state}
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  defp execute_return(status, _query, message, state, mode: _savepoint) do
    {status, message, state}
  end

  defp execute_return(status, query, message, state, _opts) do
    case status do
      :ok -> {status, query, message, state}
      _ -> {status, message, state}
    end
  end

  @doc false
  @spec handle_execute(query, params, opts, state) ::
          {:ok, query(), result(), state}
          | {:error | :disconnect, Exception.t(), state}
  def handle_execute(query, params, opts, state) do
    {status, message, new_state} = do_query(query, params, opts, state)

    case new_state.mssql do
      :idle ->
        with {:ok, _, post_commit_state} <- handle_commit(opts, new_state) do
          execute_return(status, query, message, post_commit_state, opts)
        end

      :transaction ->
        execute_return(status, query, message, new_state, opts)

      :auto_commit ->
        with {:ok, post_connect_state} <- switch_auto_commit(:off, new_state) do
          execute_return(status, query, message, post_connect_state, opts)
        end
    end
  end

  defp do_query(query, params, opts, state) do
    case ODBC.query(state.pid, query.statement, params, opts) do
      {:error, %Mssqlex.Error{odbc_code: :not_allowed_in_transaction} = reason} ->
        if state.mssql == :auto_commit do
          {:error, reason, state}
        else
          with {:ok, new_state} <- switch_auto_commit(:on, state),
               do: handle_execute(query, params, opts, new_state)
        end

      {:error, %Mssqlex.Error{odbc_code: :connection_exception} = reason} ->
        {:disconnect, reason, state}

      {:error, reason} ->
        {:error, reason, state}

      {:selected, columns, rows} ->
        {:ok,
         %Result{
           columns: Enum.map(columns, &to_string(&1)),
           rows: rows,
           num_rows: Enum.count(rows)
         }, state}

      {:updated, num_rows} ->
        {:ok, %Result{num_rows: num_rows}, state}
    end
    |> strip_query_from_tuple()
  end

  defp strip_query_from_tuple(tuple) do
    case tuple do
      {status, message, new_state} -> {status, message, new_state}
      {status, _query, message, new_state} -> {status, message, new_state}
    end
  end

  defp switch_auto_commit(new_value, state) do
    reconnect(Keyword.put(state.conn_opts, :auto_commit, new_value), state)
  end

  @doc false
  @spec handle_close(query, opts, state) ::
          {:ok, result, state}
          | {:error | :disconnect, Exception.t(), state}
  def handle_close(_query, _opts, state) do
    {:ok, %Result{}, state}
  end

  @spec ping(state :: any()) ::
          {:ok, new_state :: any()}
          | {:disconnect, Exception.t(), new_state :: any()}
  def ping(state) do
    query = %Mssqlex.Query{name: "ping", statement: "SELECT 1"}

    case do_query(query, [], [], state) do
      {:ok, _, new_state} -> {:ok, new_state}
      {:error, reason, new_state} -> {:disconnect, reason, new_state}
      other -> other
    end
  end

  @spec handle_status(opts, state) :: {DBConnection.status(), state}
  def handle_status(_, %{mssql: {status, _}} = s), do: {status, s}
  def handle_status(_, %{mssql: status} = s), do: {status, s}

  # NOT IMPLEMENTED
  def handle_declare(_query, _params, _opts, _state) do
    throw("not implemeted")
  end

  def handle_first(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end

  def handle_next(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end

  def handle_deallocate(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end

  def handle_fetch(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end
end
