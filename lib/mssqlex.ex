defmodule Mssqlex do
  @moduledoc """
  Interface for interacting with MS SQL Server via an ODBC driver for Elixir.

  It implements `DBConnection` behaviour, using `:odbc` to connect to the
  system's ODBC driver. Requires MS SQL Server ODBC driver, see
  [README](readme.html) for installation instructions.
  """

  alias Mssqlex.Query
  alias Mssqlex.Type
  alias Mssqlex.Result
  alias Mssqlex.Error
  alias Mssqlex.Protocol

  @max_rows 500

  @typedoc """
    A connection process name, pid or reference.
    A connection reference is used when making multiple requests to the same
    connection, see `transaction/3`.
  """
  @type conn :: DBConnection.conn()
  @type params :: [Type.param()]

  @doc """
  Connect to a MS SQL Server using ODBC.

  `opts` expects a keyword list with zero or more of:

    * `:odbc_driver` - The driver the adapter will use.
        * environment variable: `MSSQL_DVR`
        * default value: {ODBC Driver 17 for SQL Server}
    * `:hostname` - The server hostname.
        * environment variable: `MSSQL_HST`
        * default value: localhost
    * `:instance_name` - OPTIONAL. The name of the instance, if using named instances.
        * environment variable: `MSSQL_IN`
    * `:port` - OPTIONAL. The server port number.
        * environment variable: `MSSQL_PRT`
    * `:database` - The name of the database.
        * environment variable: `MSSQL_DB`
    * `:username` - Username.
        * environment variable: `MSSQL_UID`
    * `:password` - User's password.
        * environment variable: `MSSQL_PWD`
    * `:encrypt` - Specifies whether data should be encrypted before sending it over the network.
        * environment variable: `MSSQL_ENCRYPT`
    * `:trust_server_certificate` - When used with Encrypt, enables encryption using a self-signed server certificate.
        * environment variable: `MSSQL_TRUST_SERVER_CERT`

  `Mssqlex` uses the `DBConnection` framework and supports all `DBConnection`
  options like `:idle`, `:after_connect` etc.
  See `DBConnection.start_link/2` for more information.

  ## Examples

      iex> {:ok, pid} = Mssqlex.start_link(database: "mr_microsoft")
      {:ok, #PID<0.70.0>}
  """
  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, Error.t() | term}
  def start_link(opts) do
    ensure_deps_started!(opts)
    DBConnection.start_link(Protocol, opts)
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
    * smalldatetime, datetime, dateime2: `{{YY, MM, DD}, {HH, MM, SS, 0}}` (note that fractional
      second data is lost due to limitations of the ODBC adapter. To preserve it
      you can convert these columns to varchar during selection.)
    * uniqueidentifier, time, binary, varbinary, rowversion: not currently
      supported due to adapter limitations. Select statements for columns
      of these types must convert them to supported types (e.g. varchar).
  """

  @spec query(conn, iodata, params, Keyword.t()) ::
          {:ok, Result.t()} | {:error, Exception.t()}
  def query(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    result = DBConnection.prepare_execute(conn, query, params, opts)

    case result do
      {:ok, _, result} -> {:ok, result}
      {:error, _} = error -> error
    end
  end

  @doc """
  Executes a query against an MS SQL Server with ODBC.

  Raises an error on failure. See `query/4` for details.
  """
  @spec query!(pid(), binary(), [Type.param()], Keyword.t()) ::
          Mssqlex.Result.t()
  def query!(conn, statement, params, opts \\ []) do
    case query(conn, statement, params, opts) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end

  defp ensure_deps_started!(opts) do
    if Keyword.get(opts, :ssl, false) and
         not List.keymember?(:application.which_applications(), :ssl, 0) do
      raise """
      SSL connection can not be established because `:ssl` application is not started,
      you can add it to `extra_application` in your `mix.exs`:
        def application do
          [extra_applications: [:ssl]]
        end
      """
    end
  end

  @spec child_spec(options :: Keyword.t()) :: Supervisor.Spec.spec()
  def child_spec(opts) do
    ensure_deps_started!(opts)
    DBConnection.child_spec(Mssqlex.Protocol, opts)
  end

  def stream(%DBConnection{} = conn, query, params, options \\ []) do
    options = Keyword.put_new(options, :max_rows, @max_rows)
    %Mssqlex.Stream{conn: conn, query: query, params: params, options: options}
  end

  def prepare_execute(conn, name, statement, params, opts \\ []) do
    query = %Query{name: name, statement: statement}
    DBConnection.prepare_execute(conn, query, params, opts)
  end
end
