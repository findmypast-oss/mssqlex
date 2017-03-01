defmodule Mssqlex do
  @moduledoc """
  Interface for interacting with MS SQL Server via an ODBC driver for Elixir.

  It implements `DBConnection` behaviour, using `:odbc` to connect to the system's
  ODBC driver. Requires MS SQL Server ODBC driver, see [README](readme.html) for installation
  instructions.
  """

  @doc """
  Connect to a MS SQL Server using ODBC.

  ## Options

    * `:odbc_driver` - The driver ODBC will use (default: {ODBC Driver 13 for SQL Server})
    * `:hostname` - The server hostname (default: localhost)
    * `:database` - The name of the database (default: MSSQL_DB environment variable)
    * `:username` - Username (default: MSSQL_UID environment variable)
    * `:password` - User password (default: MSSQL_PWD environment variable)

  `Mssqlex` uses the `DBConnection` framework and supports all `DBConnection`
  options like `:idle`, `:after_connect` etc.
  See `DBConnection.start_link/2` for more information.

  ## Examples

      iex> {:ok, pid} = Mssqlex.start_link(database: "mr_microsoft")
      {:ok, #PID<0.70.0>}
  """

  alias Mssqlex.Query

  @spec start_link(Keyword.t) :: {:ok, pid}
  def start_link(opts) do

    opts = opts
    |> Keyword.put_new(:odbc_driver, "{ODBC Driver 13 for SQL Server}")
    |> Keyword.put_new(:hostname, System.get_env("MSSQL_HST") || "localhost")
    |> Keyword.put_new(:database, System.get_env("MSSQL_DB"))
    |> Keyword.put_new(:username, System.get_env("MSSQL_UID"))
    |> Keyword.put_new(:password, System.get_env("MSSQL_PWD"))

    DBConnection.start_link(Mssqlex.Protocol, opts)
  end

  @doc """
  Executes a query against an MS SQL Server with ODBC.

  Statement and params should be in the format required by the Erlang ODBC application.

  For examples see [Using the Erlang API guide](http://www1.erlang.org/doc/apps/odbc/getting_started.html#param_query).
  """
  @spec query(pid(), Query.t(), [{:odbc.odbc_data_type(), [any()]}], Keyword.t) ::
    {:ok, iodata(), Mssqlex.Result.t}
  def query(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute(conn, %Query{name: "", statement: statement}, params, opts)
  end
  @spec query(pid(), Query.t(), [{:odbc.odbc_data_type(), [any()]}], Keyword.t) ::
    {iodata(), Mssqlex.Result.t}
  def query!(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute!(conn, %Query{name: "", statement: statement}, params, opts)
  end
end
