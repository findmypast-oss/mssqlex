defmodule Mssqlex.LoginTest do
  use ExUnit.Case

  test "Given valid details, connects to database" do
    assert {:ok, pid} = Mssqlex.start_link([])
    assert {:ok, _, [{"test"}]} = Mssqlex.query(pid, "SELECT 'test'", [])
  end

  test "Given invalid details, errors" do
    Process.flag(:trap_exit, true)

    assert {:ok, pid} = Mssqlex.start_link(password: "badpass")
    assert_receive {:EXIT, ^pid, _reason}
  end
end
