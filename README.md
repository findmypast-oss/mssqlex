# Mssqlex

[![Build Status](https://travis-ci.org/findmypast-oss/mssqlex.svg?branch=master)](https://travis-ci.org/findmypast-oss/mssqlex)
[![Coverage Status](https://coveralls.io/repos/github/findmypast-oss/mssqlex/badge.svg)](https://coveralls.io/github/findmypast-oss/mssqlex)
[![Inline docs](http://inch-ci.org/github/findmypast-oss/mssqlex.svg?branch=master)](http://inch-ci.org/github/findmypast-oss/mssqlex)
[![Ebert](https://ebertapp.io/github/findmypast-oss/mssqlex.svg)](https://ebertapp.io/github/findmypast-oss/mssqlex)
[![Hex.pm](https://img.shields.io/hexpm/v/mssqlex.svg)](https://hex.pm/packages/mssqlex)
[![Hex.pm](https://img.shields.io/hexpm/l/mssqlex.svg)](https://github.com/findmypast-oss/mssqlex/blob/master/LICENSE)

Adapter to Microsoft SQL Server. Using `DBConnection` and `ODBC`.

It connects to [Ecto](https://github.com/elixir-ecto/ecto) with [MssqlEcto](https://github.com/findmypast-oss/mssql_ecto).

## Installation

Mssqlex requires the [Erlang ODBC application](http://erlang.org/doc/man/odbc.html) to be installed.
This might require the installation of an additional package depending on how you have installed
Erlang (e.g. on Ubuntu `sudo apt-get install erlang-odbc`).

Mssqlex depends on Microsoft's ODBC Driver for SQL Server. You can find installation
instructions for [Linux](https://docs.microsoft.com/en-us/sql/connect/odbc/linux/installing-the-microsoft-odbc-driver-for-sql-server-on-linux)
or [other platforms](https://docs.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server)
on the official site.

This package is availabe in Hex, the package can be installed
by adding `mssqlex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:mssqlex, "~> 0.6"}]
end
```

## Testing

Tests require an instance of SQL Server to be running on `localhost` and a valid
UID and password to be set in the `MSSQL_UID` and `MSSQL_PWD` environment
variables, respectively.

The easiest way to get an instance running is to use the SQL Server Docker image:
```sh
export MSSQL_UID=sa
export MSSQL_PWD='ThePa$$word'
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=$MSSQL_PWD' -p 1433:1433 -d microsoft/mssql-server-linux
```
