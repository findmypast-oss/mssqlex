defmodule Mssqlex.ODBC do
  use GenServer

  def start_link(conn_str, opts) do
    GenServer.start_link(__MODULE__, [{:conn_str, conn_str} | opts])
  end

  def query(pid, statement, params) do
    GenServer.call(pid, {:query, %{statement: statement, params: params}})
  end

  def init(opts) do
    :odbc.connect(opts[:conn_str], [])
  end

  def handle_call({:query, %{statement: statement}}, _from, state) do
    {:reply, :odbc.param_query(state, to_charlist(statement), []). state}
  end
end
