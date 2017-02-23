defmodule Mssqlex.TransactionTest do
  use ExUnit.Case, async: true

  alias Mssqlex.Result

  setup_all do
    {:ok, pid} = Mssqlex.start_link([])
    Mssqlex.query(pid, "DROP DATABASE transaction_test;", [])
    {:ok, _, _} = Mssqlex.query(pid, "CREATE DATABASE transaction_test;", [])

    {:ok, [pid: pid]}
  end
  # 
  # test "simple transaction test", %{pid: pid} do
  #   DBConnection.
  # end
end
