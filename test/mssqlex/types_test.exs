defmodule Mssqlex.TypesTest do
  use ExUnit.Case, async: true
  @moduletag :only

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query!(pid, "DROP DATABASE IF EXISTS types_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE types_test;", [])

    {:ok, [pid: pid]}
  end

  test "char", %{pid: pid} do
    assert {_query, %Result{rows: [["Nathan"]]}} =
      act(pid, "char(6)", ["Nathan"])
  end

  test "nchar", %{pid: pid} do
    assert {_query, %Result{rows: [["e→øæ"]]}} =
      act(pid, "nchar(4)", ["e→øæ"])
  end

  test "varchar", %{pid: pid} do
    assert {_query, %Result{rows: [["Nathan"]]}} =
      act(pid, "varchar(6)", ["Nathan"])
  end

  test "nvarchar", %{pid: pid} do
    assert {_query, %Result{rows: [["e→øæ"]]}} =
      act(pid, "nvarchar(4)", ["e→øæ"])
  end

  test "numeric(9, 0) as integer", %{pid: pid} do
    assert {_query, %Result{rows: [[123456789]]}} =
      act(pid, "numeric(9)", [123456789])
  end

  test "numeric(8, 0) as decimal", %{pid: pid} do
    assert {_query, %Result{rows: [[12345678]]}} =
      act(pid, "numeric(8)", [Decimal.new(12345678)])
  end

  test "sql_numeric(15, 0) as decimal", %{pid: pid} do
    number = Decimal.new("123456789012345")
    assert {_query, %Result{rows: [[%Decimal{} = value]]}} =
      act(pid, "numeric(15)", [number])
    assert Decimal.equal?(number, value)
  end

  test "sql_numeric(38, 0) as decimal", %{pid: pid} do
    number = Decimal.new("12345678901234567890123456789012345678")
    assert {_query, %Result{rows: [["12345678901234567890123456789012345678"]]}} =
      act(pid, "numeric(38)", [number])
  end

  test "sql_numeric(36, 0) as string", %{pid: pid} do
    number = "123456789012345678901234567890123456"
    assert {_query, %Result{rows: [["123456789012345678901234567890123456"]]}} =
      act(pid, "numeric(36)", [number])
  end

  test "sql_numeric(5, 2) as decimal", %{pid: pid} do
    number = Decimal.new("123.45")
    assert {_query, %Result{rows: [[value]]}} =
      act(pid, "numeric(5,2)", [number])
    assert Decimal.equal?(number, value)
  end

  test "sql_numeric(6, 3) as float", %{pid: pid} do
    number = Decimal.new("123.456")
    assert {_query, %Result{rows: [[value]]}} =
      act(pid, "numeric(6,3)", [123.456])
    assert Decimal.equal?(number, value)
  end

  test "bigint", %{pid: pid} do
    number = Decimal.new "-9223372036854775808"
    assert {_query, %Result{rows: [["-9223372036854775808"]]}} =
      act(pid, "bigint", [number])
  end

  test "int", %{pid: pid} do
    assert {_query, %Result{rows: [[2_147_483_647]]}} =
      act(pid, "int", [2_147_483_647])
  end

  test "smallint", %{pid: pid} do
    assert {_query, %Result{rows: [[32_767]]}} =
      act(pid, "smallint", [32_767])
  end

  test "tinyint", %{pid: pid} do
    assert {_query, %Result{rows: [[255]]}} =
      act(pid, "tinyint", [255])
  end

  test "smalldatetime as tuple", %{pid: pid} do
    assert {_query, %Result{rows: [[{{2017, 1, 1}, {12, 10, 0}}]]}} =
      act(pid, "smalldatetime", [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "datetime as tuple", %{pid: pid} do
    assert {_query, %Result{rows: [[{{2017, 1, 1}, {12, 10, 0}}]]}} =
      act(pid, "datetime", [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "datetime2 as tuple", %{pid: pid} do
    assert {_query, %Result{rows: [[{{2017, 1, 1}, {12, 10, 0}}]]}} =
      act(pid, "datetime2", [{{2017, 1, 1}, {12, 10, 0, 54}}])
  end

  test "date as tuple", %{pid: pid} do
    assert {_query, %Result{rows: [["2017-01-01"]]}} =
      act(pid, "date", [{2017, 1, 1}])
  end

  test "time as tuple", %{pid: pid} do
    do_time = fn pid, type, params ->
      Mssqlex.query!(pid, "CREATE TABLE types_test.dbo.\"#{Base.url_encode64 type}\" (test #{type})", [])
      Mssqlex.query!(pid, "INSERT INTO types_test.dbo.\"#{Base.url_encode64 type}\" VALUES (?)", params)
      Mssqlex.query!(pid, "SELECT CONVERT(nvarchar(15), test, 21) FROM types_test.dbo.\"#{Base.url_encode64 type}\"", [])
    end
    assert {_query, %Result{rows: [["12:10:00.000054"]]}} =
      do_time.(pid, "time(6)", [{12, 10, 0, 54}])
  end

  test "sql_bit", %{pid: pid} do
    assert {_query, %Result{rows: [[true]]}} =
      act(pid, "bit", [true])
  end

  defp act(pid, type, params) do
    Mssqlex.query!(pid, "CREATE TABLE types_test.dbo.\"#{Base.url_encode64 type}\" (test #{type})", [])
    Mssqlex.query!(pid, "INSERT INTO types_test.dbo.\"#{Base.url_encode64 type}\" VALUES (?)", params)
    Mssqlex.query!(pid, "SELECT * FROM types_test.dbo.\"#{Base.url_encode64 type}\"", [])
  end
end
