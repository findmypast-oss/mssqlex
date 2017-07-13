defmodule Mssqlex.QueryTest do
  use ExUnit.Case, async: true

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query!(pid, "DROP DATABASE IF EXISTS query_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE query_test;", [])

    {:ok, [pid: pid]}
  end

  test "simple select", %{pid: pid} do
    assert {:ok, _, %Result{}} = Mssqlex.query(pid,
      "CREATE TABLE query_test.dbo.simple_select (name varchar(50));", [])

    assert {:ok, _, %Result{num_rows: 1}} = Mssqlex.query(pid,
      ["INSERT INTO query_test.dbo.simple_select VALUES ('Steven');"], [])

    assert {:ok, _, %Result{columns: ["name"], num_rows: 1, rows: [["Steven"]]}}
      = Mssqlex.query(pid, "SELECT * FROM query_test.dbo.simple_select;", [])
  end

  test "parametrized queries", %{pid: pid} do
    assert {:ok, _, %Result{}} = Mssqlex.query(pid,
      "CREATE TABLE query_test.dbo.parametrized_query" <>
      "(id int, name varchar(50), joined datetime2);", [])

    assert {:ok, _, %Result{num_rows: 1}} = Mssqlex.query(pid,
      ["INSERT INTO query_test.dbo.parametrized_query VALUES (?, ?, ?);"],
      [1, "Jae", "2017-01-01 12:01:01.3450000"])

    assert {:ok, _, %Result{
               columns: ["id", "name", "joined"],
               num_rows: 1,
               rows: [[1, "Jae", _]]}} =
      Mssqlex.query(pid, "SELECT * FROM query_test.dbo.parametrized_query;", [])
  end

  test "select where in", %{pid: pid} do
    assert {:ok, _, %Result{}} = Mssqlex.query(pid,
      "CREATE TABLE query_test.dbo.select_where_in (name varchar(50), age int);", [])

    assert {:ok, _, %Result{num_rows: 1}} = Mssqlex.query(pid,
      ["INSERT INTO query_test.dbo.select_where_in VALUES (?, ?);"],
      ["Dexter", 34])

    assert {:ok, _, %Result{num_rows: 1}} = Mssqlex.query(pid,
      ["INSERT INTO query_test.dbo.select_where_in VALUES (?, ?);"],
      ["Malcolm", 41])

    assert {:ok, _, %Result{columns: ["name", "age"],
                            num_rows: 2,
                            rows: [["Dexter", 34], ["Malcolm", 41]]}} =
      Mssqlex.query(pid, "SELECT * FROM query_test.dbo.select_where_in WHERE name IN (?, ?)", ["Dexter", "Malcolm"])

    assert {:ok, _, %Result{columns: ["name", "age"],
                            num_rows: 1,
                            rows: [["Malcolm", 41]]}} =
      Mssqlex.query(pid, "SELECT * FROM query_test.dbo.select_where_in WHERE (name IN (?, ?)) AND (age = ?)", ["Dexter", "Malcolm", 41])

    assert {:ok, _, %Result{columns: ["name", "age"],
                            num_rows: 1,
                            rows: [["Dexter", 34]]}} =
      Mssqlex.query(pid, "SELECT * FROM query_test.dbo.select_where_in WHERE (age = ?) AND (name IN (?, ?))", [34, "Dexter", "Malcolm"])
  end
end
