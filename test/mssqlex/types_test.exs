defmodule Mssqlex.TypesTest do
  use ExUnit.Case, async: false

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query(pid, "DROP DATABASE types_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE types_test;", [])

    {:ok, [pid: pid]}
  end

  test "sql_char", %{pid: pid} do
    assert {_query, %Result{rows: [["Nathan"]]}} =
      act(pid, "char(6)", [{{:sql_char, 6}, ["Nathan"]}])
  end

  test "sql_wchar", %{pid: pid} do
    assert {_query, %Result{rows: [["e→øæ"]]}} =
      act(pid, "nchar(4)", [{{:sql_wchar, 4}, ["e→øæ"]}])
  end

  test "sql_numeric(9, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [[34]]}} =
      act(pid, "numeric(9)", [{{:sql_numeric, 9, 0}, ["34"]}])
  end

  test "sql_numeric(10, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [[1234567890.0]]}} =
      act(pid, "numeric(10)", [{{:sql_numeric, 10, 0}, ["1234567890"]}])
  end

  # test "sql_numeric(38, 0)", %{pid: pid} do
  #   assert {_query, %Result{rows: [["12345678901234567890123456789012345678"]]}} =
  #     act(pid, "numeric(38, 0)", [{{:sql_numeric, 38, 0}, ["12345678901234567890123456789012345678"]}])
  # end

  test "sql_numeric(5, 2)", %{pid: pid} do
    assert {_query, %Result{rows: [[123.45]]}} =
      act(pid, "numeric(5, 2)", [{{:sql_numeric, 5, 2}, ["123.45"]}])
  end

  defp act(pid, type, params) do
    Mssqlex.query!(pid, "CREATE TABLE types_test.dbo.\"#{Base.url_encode64 type}\" (test #{type})", [])
    Mssqlex.query!(pid, "INSERT INTO types_test.dbo.\"#{Base.url_encode64 type}\" VALUES (?)", params)
    Mssqlex.query!(pid, "SELECT * FROM types_test.dbo.\"#{Base.url_encode64 type}\"", [])
  end
end
