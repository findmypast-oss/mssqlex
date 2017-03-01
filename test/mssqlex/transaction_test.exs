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
    assert {:ok, %Result{}} = DBConnection.transaction(pid, fn pid ->
      {:ok, _, _} = Mssqlex.query(pid, "CREATE TABLE transaction_test.dbo.simple_transaction (name varchar(50));", [])
      {:ok, _, result} = Mssqlex.query(pid, "INSERT INTO transaction_test.dbo.simple_transaction VALUES ('Steven');", [])
      result
    end)
    assert {:ok, _query, %Result{rows: [["Steven"]]}} =
      Mssqlex.query(pid, "SELECT * from transaction_test.dbo.simple_transaction;", [])
  end

  test "nested transaction test", %{pid: pid} do
    assert {:ok, %Result{}} = DBConnection.transaction(pid, fn pid ->
      {:ok, _, _} = Mssqlex.query(pid, "CREATE TABLE transaction_test.dbo.nested_transaction (name varchar(50));", [])
      {:ok, _} = DBConnection.transaction(pid, fn pid ->
        {:ok, _, result} = Mssqlex.query(pid, "INSERT INTO transaction_test.dbo.nested_transaction VALUES ('Steven');", [])
        result
      end)
      {:ok, result} = DBConnection.transaction(pid, fn pid ->
        {:ok, _, result} = Mssqlex.query(pid, "INSERT INTO transaction_test.dbo.nested_transaction VALUES ('Jae');", [])
        result
      end)
      result
    end)
    assert {:ok, _query, %Result{rows: [["Steven"], ["Jae"]]}} =
      Mssqlex.query(pid, "SELECT * from transaction_test.dbo.nested_transaction;", [])
  end

  test "failing transaction test", %{pid: pid} do
    assert_raise Mssqlex.Error, fn ->
      DBConnection.transaction(pid, fn pid ->
        Mssqlex.query!(pid, "CREATE TABLE transaction_test.dbo.failing_transaction (name varchar(3));", [])
        {:ok, _} = DBConnection.transaction(pid, fn pid ->
          Mssqlex.query!(pid, "INSERT INTO transaction_test.dbo.failing_transaction VALUES ('Jae');", [])
        end)
        {:ok, result} = DBConnection.transaction(pid, fn pid ->
          Mssqlex.query!(pid, "INSERT INTO transaction_test.dbo.failing_transaction VALUES ('Steven');", [])
        end)
        result
      end)
    end

    assert {:error, %Mssqlex.Error{odbc_code: :base_table_or_view_not_found}} =
      Mssqlex.query(pid, "SELECT * from transaction_test.dbo.failing_transaction;", [])
  end

  test "manual rollback transaction test", %{pid: pid} do
    assert {:error, :rollback} =
      DBConnection.transaction(pid, fn pid ->
        with {:ok, _, _} <- Mssqlex.query(pid, "CREATE TABLE transaction_test.dbo.rollback_transaction (name varchar(3));", []),
             {:ok, _} <- DBConnection.transaction(pid, fn pid ->
               with {:ok, _, result} <- Mssqlex.query(pid, "INSERT INTO transaction_test.dbo.rollback_transaction VALUES ('Steven');", [])
                 do
                   result
                 else
                   {:error, reason} -> DBConnection.rollback(pid, reason)
               end
             end),
             {:ok, result} <- DBConnection.transaction(pid, fn pid ->
               with {:ok, _, result} <- Mssqlex.query(pid, "INSERT INTO transaction_test.dbo.rollback_transaction VALUES ('Jae');", [])
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
      Mssqlex.query(pid, "SELECT * from transaction_test.dbo.rollback_transaction;", [])
  end
end
