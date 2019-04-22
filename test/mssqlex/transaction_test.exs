defmodule Mssqlex.TransactionTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query!(pid, "DROP DATABASE IF EXISTS transaction_test;", [])
    {:ok, _} = Mssqlex.query(pid, "CREATE DATABASE transaction_test;", [])

    {:ok, [pid: pid]}
  end

  defp create_table(pid, table_name, char_count \\ 50) do
    query = "CREATE TABLE #{table_name} (name varchar(#{char_count}));"
    {:ok, _} = Mssqlex.query(pid, query, [])
  end

  defp insert_steven(pid, table_name) do
    query = "INSERT INTO #{table_name} VALUES ('Steven');"
    {:ok, result} = Mssqlex.query(pid, query, [])
    result
  end

  defp insert_jae(pid, table_name) do
    query = "INSERT INTO #{table_name} VALUES ('Jae');"
    {:ok, result} = Mssqlex.query(pid, query, [])
    result
  end

  defp assert_rows(pid, table_name, rows) do
    assert {:ok, %Result{columns: ["name"], rows: ^rows}} =
             Mssqlex.query(pid, "SELECT * from #{table_name};", [])
  end

  defp assert_table_not_found(pid, table_name) do
    assert {:error, %Mssqlex.Error{odbc_code: :base_table_or_view_not_found}} =
             Mssqlex.query(pid, "SELECT * from #{table_name};", [])
  end

  test "simple transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.simple"

    assert {:ok, %Result{}} =
             DBConnection.transaction(pid, fn pid ->
               create_table(pid, table_name)
               insert_steven(pid, table_name)
             end)

    assert_rows(pid, table_name, [["Steven"]])
  end

  test "nested transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.nested"

    result =
      DBConnection.transaction(pid, fn pid ->
        create_table(pid, table_name)

        {:ok, _} =
          DBConnection.transaction(pid, fn pid ->
            insert_steven(pid, table_name)
          end)

        {:ok, result} =
          DBConnection.transaction(pid, fn pid ->
            insert_jae(pid, table_name)
          end)

        result
      end)

    assert {:ok, %Result{}} = result
    assert_rows(pid, table_name, [["Steven"], ["Jae"]])
  end

  test "failing transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.failing"

    assert_raise Mssqlex.Error, fn ->
      DBConnection.transaction(pid, fn pid ->
        create_table(pid, table_name, 3)

        {:ok, _} =
          DBConnection.transaction(pid, fn pid ->
            insert_jae(pid, table_name)
          end)

        {:ok, result} =
          DBConnection.transaction(pid, fn pid ->
            Mssqlex.query!(
              pid,
              "INSERT INTO #{table_name} VALUES ('Steven');",
              []
            )
          end)

        result
      end)
    end

    assert_table_not_found(pid, table_name)
  end

  test "failing transaction timeout test", %{pid: pid} do
    timer = fn _ -> :timer.sleep(1000) end

    time_out = fn ->
      actual = DBConnection.transaction(pid, timer, timeout: 0)
      assert {:error, :rollback} = actual
    end

    time_out_error =
      "timed out because it queued and checked out the connection for longer than 0ms"

    assert capture_log(time_out) =~ time_out_error
  end

  test "manual rollback transaction test", %{pid: pid} do
    table_name = "transaction_test.dbo.roll_back"

    result =
      DBConnection.transaction(pid, fn pid ->
        with {:ok, _} <-
               DBConnection.transaction(pid, fn pid ->
                 with {:ok, _, result} <-
                        Mssqlex.query(
                          pid,
                          "INSERT INTO #{table_name} VALUES ('Steven');",
                          []
                        ) do
                   result
                 else
                   {:error, reason} -> DBConnection.rollback(pid, reason)
                 end
               end),
             {:ok, result} <-
               DBConnection.transaction(pid, fn pid ->
                 with {:ok, _, result} <-
                        Mssqlex.query(
                          pid,
                          "INSERT INTO #{table_name} VALUES ('Jae');",
                          []
                        ) do
                   result
                 else
                   {:error, reason} -> DBConnection.rollback(pid, reason)
                 end
               end) do
          result
        end
      end)

    assert {:error, :rollback} = result
    assert_table_not_found(pid, table_name)
  end

  test "Commit savepoint", %{pid: pid} do
    table_name = "transaction_test.dbo.commit_savepoint"

    result =
      DBConnection.transaction(
        pid,
        fn pid ->
          create_table(pid, table_name)
          insert_steven(pid, table_name)
        end,
        mode: :savepoint
      )

    assert {:ok, %Result{}} = result
    assert_rows(pid, table_name, [["Steven"]])
  end

  test "failing savepoint", %{pid: pid} do
    table_name = "transaction_test.dbo.failing_savepoint"

    assert_raise Mssqlex.Error, fn ->
      DBConnection.transaction(
        pid,
        fn pid ->
          create_table(pid, table_name, 3)

          DBConnection.transaction(
            pid,
            fn pid ->
              insert_jae(pid, table_name)
            end,
            mode: :savepoint
          )

          DBConnection.transaction(
            pid,
            fn pid ->
              query = "INSERT INTO #{table_name} VALUES ('Steven');"
              Mssqlex.query!(pid, query, [])
            end,
            mode: :savepoint
          )
        end,
        mode: :savepoint
      )
    end

    assert_rows(pid, table_name, [["Jae"]])
  end

  test "savepoint inside transaction", %{pid: pid} do
    table_name = "transaction_test.dbo.savepoint_in_transaction"

    DBConnection.transaction(pid, fn pid ->
      create_table(pid, table_name, 3)

      DBConnection.transaction(
        pid,
        fn pid ->
          insert_jae(pid, table_name)
        end,
        mode: :savepoint
      )
    end)

    assert_rows(pid, table_name, [["Jae"]])
  end

  test "savepoint rollback", %{pid: pid} do
    table_name = "transaction_test.dbo.savepoint_rollback"
    create_table(pid, table_name)

    DBConnection.transaction(pid, fn pid ->
      insert_jae(pid, table_name)

      DBConnection.transaction(
        pid,
        fn pid ->
          insert_steven(pid, table_name)
          DBConnection.rollback(pid, "Some reason")
        end,
        mode: :savepoint
      )
    end)

    assert_rows(pid, table_name, [])
  end
end
