defmodule Mssqlex.Protocol do
  require Logger

  @behaviour DBConnection

  @type query :: any
  @type params :: any
  @type result :: any
  @type cursor :: any

  @spec connect(opts :: Keyword.t) ::
    {:ok, state :: any} | {:error, Exception.t}
  def connect(opts) do
    conn_opts = [
      {'DRIVER', opts[:odbc_driver]},
      {'SERVER', opts[:hostname]},
      {'DATABASE', opts[:database]},
      {'UID', opts[:username]},
      {'PWD', opts[:password]}
    ]
    conn_str = Enum.reduce(conn_opts, [], fn {key, value}, acc ->
      acc ++ key ++ '=' ++ to_charlist(value) ++ ';' end)

    :odbc.connect(conn_str, [])
  end

  @spec checkout(state :: any) ::
    {:ok, new_state :: any} | {:disconnect, Exception.t, new_state :: any}
  def checkout(state) do
    {:ok, state}
  end

  @spec checkin(state :: any) ::
    {:ok, new_state :: any} | {:disconnect, Exception.t, new_state :: any}
  def checkin(state) do
    {:ok, state}
  end

  @spec ping(state :: any) ::
    {:ok, new_state :: any} | {:disconnect, Exception.t, new_state :: any}
  def ping(state) do
    {:ok, state}
  end

  @spec handle_begin(opts :: Keyword.t, state :: any) ::
    {:ok, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_begin(_opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_commit(opts :: Keyword.t, state :: any) ::
    {:ok, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_commit(_opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_rollback(opts :: Keyword.t, state :: any) ::
    {:ok, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_rollback(_opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_prepare(query, opts :: Keyword.t, state :: any) ::
    {:ok, query, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_prepare(_query, _opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_execute(query, params, opts :: Keyword.t, state :: any) ::
    {:ok, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_execute(_query, _params, _opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_close(query, opts :: Keyword.t, state :: any) ::
    {:ok, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_close(_query, _opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_declare(query, params, opts :: Keyword.t, state :: any) ::
    {:ok, cursor, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_declare(_query, _params, _opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_first(query, cursor, opts :: Keyword.t, state :: any) ::
    {:ok | :deallocate, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_first(_query, _cursor, _opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_next(query, cursor, opts :: Keyword.t, state :: any) ::
    {:ok | :deallocate, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_next(_query, _cursor, _opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_deallocate(query, cursor, opts :: Keyword.t, state :: any) ::
    {:ok, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_deallocate(_query, _cursor, _opts, state) do
    {:error, "not implemented", state}
  end

  @spec handle_info(msg :: any, state :: any) ::
    {:ok, new_state :: any} |
    {:disconnect, Exception.t, new_state :: any}
  def handle_info(msg, state) do
    Logger.debug(msg)
    {:ok, state}
  end

  @spec disconnect(err :: Exception.t, state :: any) :: :ok
  def disconnect(_error, state) do
    :odbc.disconnect(state)
  end

end
