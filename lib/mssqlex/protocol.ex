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

  @type query :: Mssqlex.Query.t
  @type params :: any
  @type result :: any
  @type cursor :: any

  @spec connect(opts :: Keyword.t) ::
    {:ok, state :: any} | {:error, Exception.t}
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

    ODBC.start_link(conn_str, [])
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

  # @spec handle_begin(opts :: Keyword.t, state :: any) ::
  #   {:ok, result, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_begin(_opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_commit(opts :: Keyword.t, state :: any) ::
  #   {:ok, result, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_commit(_opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_rollback(opts :: Keyword.t, state :: any) ::
  #   {:ok, result, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_rollback(_opts, state) do
  #   {:error, "not implemented", state}
  # end

  @spec handle_prepare(query, opts :: Keyword.t, state :: any) ::
    {:ok, query, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @spec handle_execute(query, params, opts :: Keyword.t, state :: any) ::
    {:ok, result, new_state :: any} |
    {:error | :disconnect, Exception.t, new_state :: any}
  def handle_execute(query, _params, _opts, state) do
    case ODBC.query(state, query.statement, []) do
      {:error, reason} -> {:error, reason, state}
      {:selected, _columns, rows} -> {:ok, rows, state}
      {:updated, rows_updated} -> {:ok, rows_updated, state}
    end
  end

  # @spec handle_close(query, opts :: Keyword.t, state :: any) ::
  #   {:ok, result, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_close(_query, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_declare(query, params, opts :: Keyword.t, state :: any) ::
  #   {:ok, cursor, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_declare(_query, _params, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_first(query, cursor, opts :: Keyword.t, state :: any) ::
  #   {:ok | :deallocate, result, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_first(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_next(query, cursor, opts :: Keyword.t, state :: any) ::
  #   {:ok | :deallocate, result, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_next(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_deallocate(query, cursor, opts :: Keyword.t, state :: any) ::
  #   {:ok, result, new_state :: any} |
  #   {:error | :disconnect, Exception.t, new_state :: any}
  # def handle_deallocate(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec disconnect(err :: Exception.t, state :: any) :: :ok
  # def disconnect(_error, state) do
  #   :odbc.disconnect(state)
  # end

end
