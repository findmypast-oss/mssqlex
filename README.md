# Mssqlex

[![Build Status](https://travis-ci.org/findmypast-oss/mssqlex.svg?branch=master)](https://travis-ci.org/findmypast-oss/mssqlex)

Adapter to Microsoft SQL Server. Using `DBConnection` and `ODBC`.

## Installation

Mssqlex depends on Microsoft's ODBC Driver for SQL Server. You can find installation
instructions for your platform on [the official site](https://docs.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server).

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mssqlex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:mssqlex, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mssqlex](https://hexdocs.pm/mssqlex).

## Testing

Tests require an instance of SQL Server to be running on `localhost` and a valid
UID and password to be set in the `MSSQL_UID` and `MSSQL_PWD` environment
variables, respectively.

The easiest way to get an instance running is to use the SQL Server Docker image:
```sh
export MSSQL_UID=sa
export MSSQL_PWD=ThePa$$word
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=$MSSQL_PWD' -p 1433:1433 -d microsoft/mssql-server-linux
```
