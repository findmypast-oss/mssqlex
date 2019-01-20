defmodule Mssqlex.ConstraintsTest do
  use ExUnit.Case, async: true

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query!(pid, "DROP DATABASE IF EXISTS constraints_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE constraints_test;", [])

    {:ok, [pid: pid]}
  end

  test "Unique constraint", %{pid: pid} do
    table_name = "constraints_test.dbo.uniq"

    Mssqlex.query!(
      pid,
      """
        CREATE TABLE #{table_name}
        (id int CONSTRAINT id_unique UNIQUE)
      """,
      []
    )

    Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?)", [42])

    error =
      assert_raise DBConnection.ConnectionError, fn ->
        Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?)", [42])
      end

    error = parse_error(error)
    assert error == inspect(unique: "id_unique")
  end

  test "Unique index", %{pid: pid} do
    table_name = "constraints_test.dbo.uniq_ix"

    Mssqlex.query!(
      pid,
      """
      CREATE TABLE #{table_name} (id int);
      CREATE UNIQUE INDEX id_unique ON #{table_name} (id);
      """,
      []
    )

    Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?)", [42])

    error =
      assert_raise DBConnection.ConnectionError, fn ->
        Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?)", [42])
      end

    error = parse_error(error)
    assert error == inspect(unique: "id_unique")
  end

  test "Foreign Key constraint", %{pid: pid} do
    assoc_table_name = "constraints_test.dbo.assoc"
    table_name = "constraints_test.dbo.fk"

    Mssqlex.query!(
      pid,
      """
      CREATE TABLE #{assoc_table_name}
      (id int CONSTRAINT id_pk PRIMARY KEY)
      """,
      []
    )

    Mssqlex.query!(
      pid,
      """
      CREATE TABLE #{table_name}
      (id int CONSTRAINT id_foreign FOREIGN KEY REFERENCES #{assoc_table_name})
      """,
      []
    )

    Mssqlex.query!(pid, "INSERT INTO #{assoc_table_name} VALUES (?)", [42])

    error =
      assert_raise DBConnection.ConnectionError, fn ->
        Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?)", [12])
      end

    error = parse_error(error)
    assert error == inspect(foreign_key: "id_foreign")
  end

  test "Check constraint", %{pid: pid} do
    table_name = "constraints_test.dbo.chk"

    Mssqlex.query!(
      pid,
      """
      CREATE TABLE #{table_name}
      (id int CONSTRAINT id_check CHECK (id = 1))
      """,
      []
    )

    error =
      assert_raise DBConnection.ConnectionError, fn ->
        Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?)", [42])
      end

    error = parse_error(error)
    assert error == inspect(check: "id_check")
  end

  @tag skip: "Database doesn't support this"
  test "Multiple constraints", %{pid: pid} do
    table_name = "constraints_test.dbo.mult"

    Mssqlex.query!(
      pid,
      """
      CREATE TABLE #{table_name}
      (id int CONSTRAINT id_unique UNIQUE,
       foo int CONSTRAINT foo_check CHECK (foo = 3))
      """,
      []
    )

    Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?, ?)", [42, 3])

    error =
      assert_raise DBConnection.ConnectionError, fn ->
        Mssqlex.query!(pid, "INSERT INTO #{table_name} VALUES (?, ?)", [42, 5])
      end

    error = parse_error(error)

    assert error ==
             inspect(
               unique: "id_unique",
               check: "foo_check"
             )
  end

  defp parse_error(error) do
    error =
      error.message
      |> String.trim_leading("bad return value: ")
      |> String.split("%Mssqlex.Error{constraint_violations: ")
      |> List.last()
      |> String.split("]")
      |> List.first()

    error <> "]"
  end
end
