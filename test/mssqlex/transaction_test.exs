defmodule Mssqlex.TransactionTest do
  use ExUnit.Case, async: true

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query!(pid, "DROP DATABASE IF EXISTS transaction_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE transaction_test;", [])

    {:ok, [pid: pid]}
  end

  test "simple transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.simple"
    assert {:ok, %Result{}} = DBConnection.transaction(pid, fn pid ->
      {:ok, _, _} = Mssqlex.query(pid,
        "CREATE TABLE #{table_name} (name varchar(50));", [])
      {:ok, _, result} = Mssqlex.query(pid,
        "INSERT INTO #{table_name} VALUES ('Steven');", [])
      result
    end)
    assert {:ok, _query, %Result{columns: ["name"], rows: [["Steven"]]}} =
      Mssqlex.query(pid, "SELECT * from #{table_name};", [])
  end

  test "nested transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.nested"
    assert {:ok, %Result{}} = DBConnection.transaction(pid, fn pid ->
      Mssqlex.query!(pid, "CREATE TABLE #{table_name} (name varchar(50));", [])
      {:ok, _} = DBConnection.transaction(pid, fn pid ->
        {:ok, _, result} = Mssqlex.query(pid,
          "INSERT INTO #{table_name} VALUES ('Steven');", [])
        result
      end)
      {:ok, result} = DBConnection.transaction(pid, fn pid ->
        {:ok, _, result} = Mssqlex.query(pid,
          "INSERT INTO #{table_name} VALUES ('Jae');", [])
        result
      end)
      result
    end)
    assert {:ok, _query, %Result{columns: ["name"],
      rows: [["Steven"], ["Jae"]]}} = Mssqlex.query(pid,
      "SELECT * from #{table_name};", [])
  end

  test "failing transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.failing"
    assert_raise Mssqlex.Error, fn ->
      DBConnection.transaction(pid, fn pid ->
        Mssqlex.query!(pid,
          "CREATE TABLE #{table_name} (name varchar(3));", [])
        {:ok, _} = DBConnection.transaction(pid, fn pid ->
          Mssqlex.query!(pid,
            "INSERT INTO #{table_name} VALUES ('Jae');", [])
        end)
        {:ok, result} = DBConnection.transaction(pid, fn pid ->
          Mssqlex.query!(pid,
            "INSERT INTO #{table_name} VALUES ('Steven');", [])
        end)
        result
      end)
    end

    assert {:error, %Mssqlex.Error{odbc_code: :base_table_or_view_not_found}} =
      Mssqlex.query(pid, "SELECT * from #{table_name};", [])
  end

  test "failing transaction timeout test", %{pid: pid} do
    assert_raise Mssqlex.Error, fn ->
    DBConnection.transaction(pid, fn _ ->
        :timer.sleep(1000)
      end, [timeout: 0])
    end
  end

  test "manual rollback transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.roll_back"
    assert {:error, :rollback} =
      DBConnection.transaction(pid, fn pid ->
        Mssqlex.query!(pid, "CREATE TABLE #{table_name} (name varchar(3));", [])
        with {:ok, _} <- DBConnection.transaction(pid, fn pid ->
          with {:ok, _, result} <-
                Mssqlex.query(pid,
                  "INSERT INTO #{table_name} VALUES ('Steven');", [])
            do
              result
            else
              {:error, reason} -> DBConnection.rollback(pid, reason)
          end
        end),
        {:ok, result} <- DBConnection.transaction(pid, fn pid ->
          with {:ok, _, result} <-
                Mssqlex.query(pid,
                  "INSERT INTO #{table_name} VALUES ('Jae');", [])
            do
              result
            else
              {:error, reason} -> DBConnection.rollback(pid, reason)
          end
        end)
        do
          result
        end
      end)

    assert {:error, %Mssqlex.Error{odbc_code: :base_table_or_view_not_found}} =
      Mssqlex.query(pid, "SELECT * from #{table_name};", [])
  end

  @tag :only
  test "Commit savepoint", %{pid: pid} do
    table_name = "transaction_test.dbo.commit_savepoint"
    assert {:ok, %Result{}} = DBConnection.transaction(pid, fn pid ->
      Mssqlex.query!(pid,
      "CREATE TABLE #{table_name} (name varchar(50));", [])
      {:ok, _, result} = Mssqlex.query(pid,
        "INSERT INTO #{table_name} VALUES ('Steven');", [])
      result
    end, [mode: :savepoint])
    assert {:ok, _query, %Result{columns: ["name"], rows: [["Steven"]]}} =
      Mssqlex.query(pid, "SELECT * from #{table_name};", [])
  end

  test "failing savepoint", %{pid: pid} do
    table_name = "transaction_test.dbo.failing_savepoint"
    assert_raise Mssqlex.Error, fn ->
      DBConnection.transaction(pid, fn pid ->
        Mssqlex.query!(pid,
          "CREATE TABLE #{table_name} (name varchar(3));", [])
        DBConnection.transaction(pid, fn pid ->
          Mssqlex.query!(pid,
            "INSERT INTO #{table_name} VALUES ('Jae');", [])
        end, [mode: :savepoint])
        DBConnection.transaction(pid, fn pid ->
          Mssqlex.query!(pid,
            "INSERT INTO #{table_name} VALUES ('Steven');", [])
        end, [mode: :savepoint])
      end, [mode: :savepoint])
    end

    assert {:ok, _, %Result{columns: ["name"], rows: [["Jae"]]}} =
      Mssqlex.query(pid, "SELECT * from #{table_name};", [])
  end
end
