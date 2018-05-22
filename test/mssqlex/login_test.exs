defmodule Mssqlex.LoginTest do
  use ExUnit.Case, async: false

  alias Mssqlex.Result

  @check_encryption """
  SELECT encrypt_option
  FROM sys.dm_exec_connections
  WHERE session_id = @@SPID
  """

  test "Given valid details, connects to database" do
    assert {:ok, pid} = Mssqlex.start_link([])
    assert {:ok, _, %Result{num_rows: 1, rows: [["test"]]}} =
      Mssqlex.query(pid, "SELECT 'test'", [])
  end

  test "connects with encryption" do
    assert {:ok, pid} = Mssqlex.start_link(encrypt: true, trust_server_certificate: true)
    assert {:ok, _, %Result{num_rows: 1, rows: [["TRUE"]]}} =
      Mssqlex.query(pid, @check_encryption, [])
  end

  test "Given invalid details, errors" do
    Process.flag(:trap_exit, true)

    assert {:ok, pid} = Mssqlex.start_link(password: "badpass")
    assert_receive {:EXIT, ^pid,
                    %Mssqlex.Error{odbc_code: :invalid_authorization}}
  end
end
