defmodule Mssqlex.TypesTest do
  use ExUnit.Case, async: true

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query!(pid, "DROP DATABASE IF EXISTS types_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE types_test;", [])

    {:ok, [pid: pid]}
  end

  test "sql_char", %{pid: pid} do
    assert {_query, %Result{rows: [["Nathan"]]}} =
      act(pid, "char(6)", [{{:sql_char, 6}, ["Nathan"]}])
  end

  test "sql_wchar", %{pid: pid} do
    assert {_query, %Result{rows: [[value]]}} =
      act(pid, "nchar(4)", [{{:sql_wchar, 4}, ["e→øæ"]}])
    assert "e→øæ" = :unicode.characters_to_binary(value, {:utf16, :little})
  end

  test "sql_varchar", %{pid: pid} do
    assert {_query, %Result{rows: [["Nathan"]]}} =
      act(pid, "varchar(6)", [{{:sql_varchar, 6}, ["Nathan"]}])
  end

  test "sql_wvarchar", %{pid: pid} do
    assert {_query, %Result{rows: [[value]]}} =
      act(pid, "nvarchar(4)", [{{:sql_wvarchar, 4}, ["e→øæ"]}])
    assert "e→øæ" = :unicode.characters_to_binary(value, {:utf16, :little})
  end

  test "sql_numeric(9, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [[34]]}} =
      act(pid, "numeric(9)", [{{:sql_numeric, 9, 0}, ["34"]}])
  end

  test "sql_numeric(10, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [[1234567890.0]]}} =
      act(pid, "numeric(10)", [{{:sql_numeric, 10, 0}, ["1234567890"]}])
  end

  test "sql_numeric(38, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [["12345678901234567890123456789012345678"]]}} =
      act(pid, "numeric(38, 0)", [{{:sql_numeric, 38, 0}, ["12345678901234567890123456789012345678"]}])
  end

  test "sql_numeric(5, 2)", %{pid: pid} do
    assert {_query, %Result{rows: [[123.45]]}} =
      act(pid, "numeric(5, 2)", [{{:sql_numeric, 5, 2}, ["123.45"]}])
  end

  test "sql_decimal(7, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [[1234567]]}} =
      act(pid, "decimal(7)", [{{:sql_decimal, 7, 0}, ["1234567"]}])
  end

  test "sql_decimal(13, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [[1234567890123.0]]}} =
      act(pid, "decimal(13)", [{{:sql_decimal, 13, 0}, ["1234567890123"]}])
  end

  test "sql_decimal(32, 0)", %{pid: pid} do
    assert {_query, %Result{rows: [["12345678901234567890123456789012"]]}} =
      act(pid, "decimal(32)", [{{:sql_decimal, 32, 0}, ["12345678901234567890123456789012"]}])
  end

  test "sql_decimal(7, 3)", %{pid: pid} do
    assert {_query, %Result{rows: [[1234.567]]}} =
      act(pid, "decimal(7, 3)", [{{:sql_decimal, 7, 3}, ["1234.567"]}])
  end

  test "bigint (as sql_numeric)", %{pid: pid} do
    assert {_query, %Result{rows: [["-9223372036854775808"], ["9223372036854775807"]]}} =
      act(pid, "bigint", [{{:sql_numeric, 19, 0}, ["-9223372036854775808", "9223372036854775807"]}])
  end

  test "sql_integer", %{pid: pid} do
    assert {_query, %Result{rows: [[2_147_483_647], [-2_147_483_648]]}} =
      act(pid, "int", [{:sql_integer, [2_147_483_647, -2_147_483_648]}])
  end

  test "sql_smallint", %{pid: pid} do
    assert {_query, %Result{rows: [[-32_768], [32_767]]}} =
      act(pid, "smallint", [{:sql_integer, [-32_768, 32_767]}])
  end

  test "sql_tinyint", %{pid: pid} do
    assert {_query, %Result{rows: [[0], [255]]}} =
      act(pid, "tinyint", [{:sql_integer, [0, 255]}])
  end

  test "sql_real", %{pid: pid} do
    assert {_query, %Result{rows: [[value]]}} =
      act(pid, "real", [{:sql_real, [12345.67]}])
    assert 12345.67 = Float.round(value, 2)
  end

  test "sql_float(24)", %{pid: pid} do
    assert {_query, %Result{rows: [[value]]}} =
      act(pid, "float(24)", [{{:sql_float, 24}, [12345.67]}])
    assert 12345.67 = Float.round(value, 2)
  end

  test "sql_double", %{pid: pid} do
    assert {_query, %Result{rows: [[1234567890.12345]]}} =
      act(pid, "double precision", [{:sql_double, [1234567890.12345]}])
  end

  test "sql_float(53)", %{pid: pid} do
    assert {_query, %Result{rows: [[1234567890.12345]]}} =
      act(pid, "float(53)", [{{:sql_float, 53}, [1234567890.12345]}])
  end

  test "smalldatetime (as varchar)", %{pid: pid} do
    assert {_query, %Result{rows: [[{{2017, 1, 1}, {12, 10, 0}}]]}} =
      act(pid, "smalldatetime", [{{:sql_varchar, 19}, ["2017-01-01 12:10:00"]}])
  end

  test "datetime (as varchar)", %{pid: pid} do
    assert {_query, %Result{rows: [[{{2017, 1, 1}, {12, 10, 0}}]]}} =
      act(pid, "datetime", [{{:sql_varchar, 23}, ["2017-01-01 12:10:00.99"]}])
  end

  test "datetime2 (as varchar)", %{pid: pid} do
    assert {_query, %Result{rows: [[{{2017, 1, 1}, {12, 10, 0}}]]}} =
      act(pid, "datetime2", [{{:sql_varchar, 27}, ["2017-01-01 12:10:00.9999997"]}])
  end

  test "sql_bit", %{pid: pid} do
    assert {_query, %Result{rows: [[false], [true]]}} =
      act(pid, "bit", [{:sql_bit, [false, true]}])
  end

  defp act(pid, type, params) do
    Mssqlex.query!(pid, "CREATE TABLE types_test.dbo.\"#{Base.url_encode64 type}\" (test #{type})", [])
    Mssqlex.query!(pid, "INSERT INTO types_test.dbo.\"#{Base.url_encode64 type}\" VALUES (?)", params)
    Mssqlex.query!(pid, "SELECT * FROM types_test.dbo.\"#{Base.url_encode64 type}\"", [])
  end
end
