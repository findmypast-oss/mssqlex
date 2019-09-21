defmodule Mssqlex.TypeParser do
  alias Mssqlex.TypeParser.Agent, as: TypeAgent

  @moduledoc """
  Parser for table column data types.
  """

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
    case build_table_list(tail, []) do
      [table] ->
        table_columns = TypeAgent.fetch_table_columns(pid, table)
        parse(table_columns, queried_columns, rows)

      [] ->
        rows

      table_list ->
        table_list
        |> Enum.reverse()
        |> Enum.map(&TypeAgent.fetch_table_columns(pid, &1))
        |> parse_tables(queried_columns, rows)
    end
  end

  defp build_table_list([], tables), do: tables

  defp build_table_list(["FROM", "(SELECT" | tail], tables),
    do: build_table_list(tail, tables)

  defp build_table_list(["FROM", table | tail], tables),
    do: build_table_list(tail, [table | tables])

  defp build_table_list(["JOIN", table | tail], tables),
    do: build_table_list(tail, [table | tables])

  defp build_table_list([_ | tail], tables), do: build_table_list(tail, tables)

  defp parse_tables(tables, queried_columns, rows) do
    types =
      Enum.map(queried_columns, fn column ->
        tables
        |> Enum.map(&Map.get(&1, column))
        |> Enum.filter(& &1)
        |> Enum.sort()
        |> Enum.dedup()
      end)

    rows
    |> Enum.map(&Enum.zip(types, &1))
    |> Enum.map(&parse_and_select/1)
  end

  defp parse_and_select(row) do
    parse(row)
    |> Enum.map(fn col ->
      col =
        col
        |> Enum.sort()
        |> Enum.dedup()

      if Enum.count(col) == 1 do
        List.first(col)
      else
        raise "unable to determine correct type of #{inspect(col)}"
      end
    end)
  end

  defp parse(table_columns, queried_columns, rows) do
    types = Enum.map(queried_columns, &Map.get(table_columns, &1))

    rows
    |> Enum.map(&Enum.zip(types, &1))
    |> Enum.map(&parse/1)
  end

  defp parse([]), do: []
  defp parse([head | tail]), do: [parse(head) | parse(tail)]

  defp parse({types, data}) when is_list(types) do
    Enum.map(types, fn type -> parse({type, data}) end)
  end

  defp parse({_type, :null}), do: :null

  defp parse({:SQL_BIGINT, data}) when is_binary(data),
    do: String.to_integer(data)

  defp parse({:sql_integer, data}) when is_binary(data),
    do: String.to_integer(data)

  defp parse({{:sql_numeric, _, _}, data}) when is_binary(data) do
    {float, ""} = Float.parse(data)
    Decimal.from_float(float)
  end

  defp parse({{:sql_decimal, _, _}, data}) when is_binary(data) do
    {float, ""} = Float.parse(data)
    Decimal.from_float(float)
  end

  defp parse({_type, data}) do
    # {_type, data} |> IO.inspect()
    data
  end
end
