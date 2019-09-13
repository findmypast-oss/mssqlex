defmodule Mssqlex.TypeParser.Agent do
  use Agent

  def start_link(pid) do
    Agent.start_link(fn -> %{} end, name: via_tuple(pid))
  end

  defp via_tuple(pid), do: {:via, :gproc, {:n, :l, {__MODULE__, pid}}}

  def fetch_table_columns(pid, table) do
    table = to_charlist(table)
    Agent.get_and_update(via_tuple(pid), &fetch_table_columns(pid, table, &1))
  end

  def fetch_table_columns(pid, table, tables) do
    table_columns = get_table_columns(pid, table, tables)
    tables = Map.put(tables, table, table_columns)
    {table_columns, tables}
  end

  @doc false
  defp get_table_columns(pid, table, tables) do
    case Map.get(tables, table) do
      nil ->
        pid
        |> Mssqlex.ODBC.describe(table)
        |> elem(1)
        |> Map.new()

      table_columns ->
        table_columns
    end
  end
end
