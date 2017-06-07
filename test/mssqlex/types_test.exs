defmodule Mssqlex.TypesTest do
  use ExUnit.Case, async: true

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query!(pid, "DROP DATABASE IF EXISTS types_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE types_test COLLATE Latin1_General_CS_AS_KS_WS;", [])

    {:ok, [pid: pid]}
  end

  test "char", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [["Nathan"]]}} =
      act(pid, "char(6)", ["Nathan"])
  end

  test "nchar", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [["e→øæ"]]}} =
      act(pid, "nchar(4)", ["e→øæ"])
  end

  test "nchar with preserved encoding", %{pid: pid} do
    expected = :unicode.characters_to_binary("e→ø",
      :unicode, {:utf16, :little})
    assert {_query, %Result{columns: ["test"], rows: [[^expected]]}} =
      act(pid, "nchar(3)", ["e→ø"], [preserve_encoding: true])
  end

  test "varchar", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [["Nathan"]]}} =
      act(pid, "varchar(6)", ["Nathan"])
  end

  test "varchar with unicode characters", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [["Nathan Molnár"]]}} =
      act(pid, "varchar(15)", ["Nathan Molnár"])
  end

  test "nvarchar", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [["e→øæ"]]}} =
      act(pid, "nvarchar(4)", ["e→øæ"])
  end

  test "nvarchar with preserved encoding", %{pid: pid} do
    expected = :unicode.characters_to_binary("e→ø",
      :unicode, {:utf16, :little})
    assert {_query, %Result{columns: ["test"], rows: [[^expected]]}} =
      act(pid, "nvarchar(3)", ["e→ø"], [preserve_encoding: true])
  end

  test "numeric(9, 0) as integer", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [[123456789]]}} =
      act(pid, "numeric(9)", [123456789])
  end

  test "numeric(8, 0) as decimal", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [[12345678]]}} =
      act(pid, "numeric(8)", [Decimal.new(12345678)])
  end

  test "numeric(15, 0) as decimal", %{pid: pid} do
    number = Decimal.new("123456789012345")
    assert {_query, %Result{columns: ["test"], rows: [[%Decimal{} = value]]}} =
      act(pid, "numeric(15)", [number])
    assert Decimal.equal?(number, value)
  end

  test "numeric(38, 0) as decimal", %{pid: pid} do
    number = "12345678901234567890123456789012345678"
    assert {_query, %Result{columns: ["test"], rows: [[^number]]}} =
      act(pid, "numeric(38)", [Decimal.new(number)])
  end

  test "numeric(36, 0) as string", %{pid: pid} do
    number = "123456789012345678901234567890123456"
    assert {_query, %Result{columns: ["test"], rows: [[^number]]}} =
      act(pid, "numeric(36)", [number])
  end

  test "numeric(5, 2) as decimal", %{pid: pid} do
    number = Decimal.new("123.45")
    assert {_query, %Result{columns: ["test"], rows: [[value]]}} =
      act(pid, "numeric(5,2)", [number])
    assert Decimal.equal?(number, value)
  end

  test "numeric(6, 3) as float", %{pid: pid} do
    number = Decimal.new("123.456")
    assert {_query, %Result{columns: ["test"], rows: [[value]]}} =
      act(pid, "numeric(6,3)", [123.456])
    assert Decimal.equal?(number, value)
  end

  test "real as decimal", %{pid: pid} do
    number = Decimal.new("123.45")
    assert {_query, %Result{columns: ["test"], rows: [[%Decimal{} = value]]}} =
      act(pid, "real", [number])
    assert Decimal.equal?(number, Decimal.round(value, 2))
  end

  test "float as decimal", %{pid: pid} do
    number = Decimal.new("123.45")
    assert {_query, %Result{columns: ["test"], rows: [[%Decimal{} = value]]}} =
      act(pid, "float", [number])
    assert Decimal.equal?(number, Decimal.round(value, 2))
  end

  test "double as decimal", %{pid: pid} do
    number = Decimal.new("1.12345678901234")
    assert {_query, %Result{columns: ["test"], rows: [[%Decimal{} = value]]}} =
      act(pid, "double precision", [number])
    assert Decimal.equal?(number, value)
  end

  test "money as decimal", %{pid: pid} do
    number = Decimal.new("1000000.45")
    assert {_query, %Result{columns: ["test"], rows: [["1000000.4500"]]}} =
      act(pid, "money", [number])
  end

  test "smallmoney as decimal", %{pid: pid} do
    number = Decimal.new("123.45")
    assert {_query, %Result{columns: ["test"], rows: [[value]]}} =
      act(pid, "smallmoney", [number])
    assert Decimal.equal?(number, value)
  end

  test "bigint", %{pid: pid} do
    assert {_query, %Result{columns: ["test"],
      rows: [["-9223372036854775808"]]}} = act(pid,
      "bigint", [-9223372036854775808])
  end

  test "int", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [[2_147_483_647]]}} =
      act(pid, "int", [2_147_483_647])
  end

  test "smallint", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [[32_767]]}} =
      act(pid, "smallint", [32_767])
  end

  test "tinyint", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [[255]]}} =
      act(pid, "tinyint", [255])
  end

  test "smalldatetime as tuple", %{pid: pid} do
    assert {_query, %Result{columns: ["test"],
      rows: [[{{2017, 1, 1}, {12, 10, 0, 0}}]]}} = act(pid, "smalldatetime",
      [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "datetime as tuple", %{pid: pid} do
    assert {_query, %Result{columns: ["test"],
      rows: [[{{2017, 1, 1}, {12, 10, 0, 0}}]]}} = act(pid, "datetime",
      [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "datetime2 as tuple", %{pid: pid} do
    assert {_query, %Result{columns: ["test"],
      rows: [[{{2017, 1, 1}, {12, 10, 0, 0}}]]}} = act(pid, "datetime2",
      [{{2017, 1, 1}, {12, 10, 0, 0}}])
  end

  test "date as tuple", %{pid: pid} do
    assert {_query, %Result{columns: ["test"], rows: [["2017-01-01"]]}} =
      act(pid, "date", [{2017, 1, 1}])
  end

  test "time as tuple", %{pid: pid} do
    do_act = fn pid, type, params ->
      Mssqlex.query!(pid,
        "CREATE TABLE #{table_name(type)} (test #{type})", [])
      Mssqlex.query!(pid,
        "INSERT INTO #{table_name(type)} VALUES (?)", params)
      Mssqlex.query!(pid,
        "SELECT CONVERT(nvarchar(15), test, 21) FROM #{table_name(type)}", [])
    end
    assert {_query, %Result{rows: [["12:10:00.000054"]]}} =
      do_act.(pid, "time(6)", [{12, 10, 0, 54}])
  end

  test "bit", %{pid: pid} do
    assert {_query, %Result{rows: [[true]]}} =
      act(pid, "bit", [true])
  end

  test "uniqueidentifier", %{pid: pid} do
    do_act = fn pid, type, params ->
      Mssqlex.query!(pid,
        "CREATE TABLE #{table_name(type)} (test #{type})", [])
      Mssqlex.query!(pid,
        "INSERT INTO #{table_name(type)} VALUES (?)", params)
      Mssqlex.query!(pid,
        "SELECT CONVERT(char(36), test) FROM #{table_name(type)}", [])
    end

    assert {_query, %Result{rows: [["6F9619FF-8B86-D011-B42D-00C04FC964FF"]]}} =
      do_act.(pid, "uniqueidentifier", ["6F9619FF-8B86-D011-B42D-00C04FC964FF"])
  end

  test "rowversion", %{pid: pid} do
    type = "rowversion"

    Mssqlex.query!(pid,
      "CREATE TABLE #{table_name(type)} (test #{type}, num int)", [])
    Mssqlex.query!(pid,
      "INSERT INTO #{table_name(type)} (num) VALUES (?)", [1])
    Mssqlex.query!(pid,
      "INSERT INTO #{table_name(type)} (num) VALUES (?)", [2])

    assert {_query, %Result{rows: [[2001], [2002]]}} =
      Mssqlex.query!(pid,
        "SELECT CONVERT(int, test) FROM #{table_name(type)}", [])
  end

  test "binary", %{pid: pid} do
    do_act = fn pid, type, params ->
      Mssqlex.query!(pid,
        "CREATE TABLE #{table_name(type)} (test #{type})", [])
      Mssqlex.query!(pid,
        "INSERT INTO #{table_name(type)} VALUES (?)", params)
      Mssqlex.query!(pid,
        "SELECT CONVERT(int, test) FROM #{table_name(type)}", [])
    end

    assert {_query, %Result{rows: [[255]]}} =
      do_act.(pid, "binary", [255])
  end

  test "varbinary", %{pid: pid} do
    do_act = fn pid, type, params ->
      Mssqlex.query!(pid,
        "CREATE TABLE #{table_name(type)} (test #{type})", [])
      Mssqlex.query!(pid,
        "INSERT INTO #{table_name(type)} VALUES (?)", params)
      Mssqlex.query!(pid,
        "SELECT CONVERT(int, test) FROM #{table_name(type)}", [])
    end

    assert {_query, %Result{rows: [[255]]}} =
      do_act.(pid, "varbinary", [255])
  end

  test "null", %{pid: pid} do
    type = "char(13)"

    Mssqlex.query!(pid,
      "CREATE TABLE #{table_name(type)} (test #{type}, num int)", [])
    Mssqlex.query!(pid,
      "INSERT INTO #{table_name(type)} (num) VALUES (?)", [2])

    assert {_query, %Result{rows: [[nil]]}} =
      Mssqlex.query!(pid,
        "SELECT CONVERT(int, test) FROM #{table_name(type)}", [])
  end

  test "invalid input type", %{pid: pid} do
    assert_raise Mssqlex.Error, ~r/unrecognised type/, fn ->
      act(pid, "char(10)", [{"Nathan"}])
    end
  end

  test "invalid input binary", %{pid: pid} do
    assert_raise Mssqlex.Error, ~r/failed to convert/, fn ->
      act(pid, "char(12)", [<<110, 0, 200>>])
    end
  end

  defp table_name(type) do
    ~s(types_test.dbo."#{Base.url_encode64 type}")
  end
  defp act(pid, type, params, opts \\ []) do
    Mssqlex.query!(pid,
      "CREATE TABLE #{table_name(type)} (test #{type})", [], opts)
    Mssqlex.query!(pid,
      "INSERT INTO #{table_name(type)} VALUES (?)", params, opts)
    Mssqlex.query!(pid,
      "SELECT * FROM #{table_name(type)}", [], opts)
  end
end
