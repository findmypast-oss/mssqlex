defmodule Mssqlex.StorageTest do
  use ExUnit.Case, async: true

  alias Mssqlex.Result

  setup do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query(pid, "DROP DATABASE storage_test", [])
    {:ok, [pid: pid]}
  end

  test "can create and drop database", %{pid: pid} do
    assert {:ok, _, %Result{}} = Mssqlex.query(pid,
      "CREATE DATABASE storage_test", [])
    assert {:ok, _, %Result{}} = Mssqlex.query(pid,
      "DROP DATABASE storage_test", [])
  end

  test "returns correct error when dropping database that doesn't exist", %{pid: pid} do
    assert {:error, %{odbc_code: :base_table_or_view_not_found}} = Mssqlex.query(pid,
      "DROP DATABASE storage_test", [])
  end

  test "returns correct error when creating a database that already exists", %{pid: pid} do
    assert {:ok, _, %Result{}} = Mssqlex.query(pid,
      "CREATE DATABASE storage_test", [])
    assert {:error, %{odbc_code: :database_already_exists}} = Mssqlex.query(pid,
      "CREATE DATABASE storage_test", [])
  end
end
