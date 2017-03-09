defmodule Mssqlex do
  @moduledoc """
  Interface for interacting with MS SQL Server via an ODBC driver for Elixir.

  It implements `DBConnection` behaviour, using `:odbc` to connect to the
  system's ODBC driver. Requires MS SQL Server ODBC driver, see
  [README](readme.html) for installation instructions.
  """

  alias Mssqlex.Query
  alias Mssqlex.Type

  @doc """
  Connect to a MS SQL Server using ODBC.

  `opts` expects a keyword list with zero or more of:

    * `:odbc_driver` - The driver the adapter will use
      (default: {ODBC Driver 13 for SQL Server})
    * `:hostname` - The server hostname (default: localhost)
    * `:database` - The name of the database
      (default: MSSQL_DB environment variable)
    * `:username` - Username (default: MSSQL_UID environment variable)
    * `:password` - User password (default: MSSQL_PWD environment variable)

  `Mssqlex` uses the `DBConnection` framework and supports all `DBConnection`
  options like `:idle`, `:after_connect` etc.
  See `DBConnection.start_link/2` for more information.

  ## Examples

      iex> {:ok, pid} = Mssqlex.start_link(database: "mr_microsoft")
      {:ok, #PID<0.70.0>}
  """
  @spec start_link(Keyword.t) :: {:ok, pid}
  def start_link(opts) do
    DBConnection.start_link(Mssqlex.Protocol, opts)
  end

  @doc """
  Executes a query against an MS SQL Server with ODBC.

  `conn` expects a `Mssqlex` process identifier.

  `statement` expects a SQL query string.

  `params` expects a list of values in one of the following formats:

    * Strings with only valid ASCII characters, which will be sent to the
      database as strings.
    * Other binaries, which will be converted to UTF16 Little Endian binaries
      (which is what SQL Server expects for its unicode fields).
    * `Decimal` structs, which will be encoded as strings so they can be
      sent to the database with arbitrary precision.
    * Integers, which will be sent as-is if under 10 digits or encoded
      as strings for larger numbers.
    * Floats, which will be encoded as strings.
    * Time as `{hour, minute, sec, usec}` tuples, which will be encoded as
      strings.
    * Dates as `{year, month, day}` tuples, which will be encoded as strings.
    * Datetime as `{{hour, minute, sec, usec}, {year, month, day}}` tuples which
      will be encoded as strings. Note that attempting to insert a value with
      usec > 0 into a 'datetime' or 'smalldatetime' column is an error since
      those column types don't have enough precision to store usec data.

  `opts` expects a keyword list with zero or more of:

    * `:preserve_encoding`: If `true`, doesn't convert returned binaries from
    UTF16LE to UTF8. Default: `false`.
    * `:mode` - set to `:savepoint` to use a savepoint to rollback to before the
    query on error, otherwise set to `:transaction` (default: `:transaction`);

  Result values will be encoded according to the following conversions:

    * char and varchar: strings.
    * nchar and nvarchar: strings unless `:preserve_encoding` is set to `true`
      in which case they will be returned as UTF16 Little Endian binaries.
    * int, smallint, tinyint, decimal and numeric when precision < 10 and
      scale = 0 (i.e. effectively integers): integers.
    * float, real, double precision, decimal and numeric when precision between
      10 and 15 and/or scale between 1 and 15: `Decimal` structs.
    * bigint, money, decimal and numeric when precision > 15: strings.
    * date: `{year, month, day}`
    * smalldatetime, datetime, dateime2: `{{YY, MM, DD}, {HH, MM, SS}}` (note that fractional
      second data is lost due to limitations of the ODBC adapter. To preserve it
      you can convert these columns to varchar during selection.)
    * uniqueidentifier, time, binary, varbinary, rowversion: not currently
      supported due to adapter limitations. Select statements for columns
      of these types must convert them to supported types (e.g. varchar).
  """
  @spec query(pid(), binary(), [Type.param()], Keyword.t) ::
    {:ok, iodata(), Mssqlex.Result.t}
  def query(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute(
      conn, %Query{name: "", statement: statement}, params, opts)
  end

  @doc """
  Executes a query against an MS SQL Server with ODBC.

  Raises an error on failure. See `query/4` for details.
  """
  @spec query!(pid(), binary(), [Type.param()], Keyword.t) ::
    {iodata(), Mssqlex.Result.t}
  def query!(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute!(
      conn, %Query{name: "", statement: statement}, params, opts)
  end
end
