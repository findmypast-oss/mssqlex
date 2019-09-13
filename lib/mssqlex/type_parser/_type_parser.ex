defmodule Mssqlex.TypeParser do
  alias Mssqlex.TypeParser.Agent, as: TypeAgent

  def parse_rows(pid, statement, queried_columns, rows)
      when is_binary(statement) do
    statement = String.split(statement)
    parse_rows(pid, statement, queried_columns, rows)
  end

  def parse_rows(pid, statement, queried_columns, rows)
      when is_list(statement) do
    case statement do
      ["INSERT INTO ", [34, table, 34] | _] ->
        table_columns = TypeAgent.fetch_table_columns(pid, table)
        parse(table_columns, queried_columns, rows)

      ["UPDATE ", [34, table, 34] | _] ->
        table_columns = TypeAgent.fetch_table_columns(pid, table)
        parse(table_columns, queried_columns, rows)

      ["DELETE" | tail] ->
        find_tables(pid, tail, queried_columns, rows)

      ["SELECT" | tail] ->
        find_tables(pid, tail, queried_columns, rows)

      ["UPDATE" | tail] ->
        find_tables(pid, tail, queried_columns, rows)
    end
  end

  defp find_tables(pid, tail, queried_columns, rows) do
        case parse_tables(tail, []) do
          [table] ->
            table_columns = TypeAgent.fetch_table_columns(pid, table)
            parse(table_columns, queried_columns, rows)

          [] ->
            rows

          table_list ->
            [table | _tail] = Enum.reverse(table_list)
            table_columns = TypeAgent.fetch_table_columns(pid, table)
            parse(table_columns, queried_columns, rows)
        end
  end

  defp parse_tables([], tables), do: tables

  defp parse_tables(["FROM", "(SELECT" | tail], tables),
    do: parse_tables(tail, tables)

  defp parse_tables(["FROM", table | tail], tables),
    do: parse_tables(tail, [table | tables])

  defp parse_tables([_ | tail], tables), do: parse_tables(tail, tables)

  defp parse(table_columns, queried_columns, rows) do
    types = Enum.map(queried_columns, &Map.get(table_columns, &1))

    rows
    |> Enum.map(&Enum.zip(types, &1))
    |> Enum.map(&parse/1)
  end

  defp parse([]), do: []
  defp parse([head | tail]), do: [parse(head) | parse(tail)]
  defp parse({_type, :null}), do: :null
  defp parse({:SQL_BIGINT, data}), do: String.to_integer(data)

  defp parse({:sql_integer, data}) when is_binary(data),
    do: String.to_integer(data)

  defp parse({_type, data}) do
    #{_type, data} |> IO.inspect()
    data
  end
end
