defmodule Mssqlex.ODBC do
  @moduledoc """
  Adapter to Erlang's `:odbc` module.

  This module is a GenServer that handles communication between Elixir
  and Erlang's `:odbc` module. Transformations are kept to a minimum,
  primarily just translating binaries to charlists and vice versa.

  It is used by `Mssqlex.Protocol` and should not generally be
  accessed directly.
  """
  use GenServer

  alias Mssqlex.Error

  @doc """
  Starts the connection process to the ODBC driver.

  `conn_str` should be a connection string in the format required by
  your ODBC driver.
  `opts` will be passed verbatim to `:odbc.connect/2`.
  """
  @spec start_link(binary(), Keyword.t) :: {:ok, pid()}
  def start_link(conn_str, opts) do
    GenServer.start_link(__MODULE__, [{:conn_str, to_charlist(conn_str)} | opts])
  end

  @doc """
  Sends a parametrized query to the ODBC driver.

  Interface to `:odbc.param_query/3`. See [Erlang's ODBC guide](http://erlang.org/doc/apps/odbc/getting_started.html)
  for usage details and examples.
  """
  @spec query(pid(), binary(), Keyword.t) :: {:selected, [binary()], [tuple()] | {:updated, non_neg_integer()}} | {:error, Exception.t}
  def query(pid, statement, params) do
    GenServer.call(pid, {:query, %{statement: statement, params: params}})
  end

  def commit(pid) do
    GenServer.call(pid, :commit)
  end

  # GenServer callbacks

  @doc false
  def init(opts) do
    connect_opts = opts
    |> Keyword.delete_first(:conn_str)
    |> Keyword.put(:binary_strings, :on)
    |> Keyword.put(:auto_commit, :off)
    |> Keyword.put_new(:timeout, 100)
    case handle_errors(:odbc.connect(opts[:conn_str], connect_opts)) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> {:stop, reason}
    end
  end

  @doc false
  def handle_call({:query, %{statement: statement}}, _from, state) do
    {:reply, handle_errors(:odbc.param_query(state, to_charlist(statement), [])), state}
  end

  def handle_call(:commit, _from, state) do
    {:reply, :odbc.commit(state, :commit), state}
  end

  defp handle_errors({:error, reason}), do: {:error, reason |> to_string |> Error.exception}
  defp handle_errors(term), do: term
end
