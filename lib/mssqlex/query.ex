defmodule Mssqlex.Query do
  @moduledoc """
  Implementation of `DBConnection.Query` for `Mssqlex`.

  The structure is:
    * `name` - currently not used.
    * `statement` - SQL statement to run using `:odbc`.
  """

  @type t :: %__MODULE__{
    name: iodata,
    statement: iodata,
  }

  defstruct [:name, :statement]
end

defimpl DBConnection.Query, for: Mssqlex.Query do

  alias Mssqlex.Result
  alias Mssqlex.Type

  @unicode_types [:sql_wchar, :sql_wvarchar, :sql_wlongvarchar]
  @numeric_types [:sql_numeric, :sql_decimal]

  def parse(query, _opts), do: query
  def describe(query, _opts), do: query
  def encode(_query, params, _opts) do
    Enum.map(params, &Type.encode/1)
  end

  def decode(_query, %Result{rows: rows} = result, _opts) when not is_nil(rows) do
    Map.put(result, :rows, Enum.map(rows, fn row -> Enum.map(row, &Type.decode/1) end))
  end
  def decode(_query, result, _opts), do: result
end

defimpl String.Chars, for: Mssqlex.Query do
  def to_string(%Mssqlex.Query{statement: statement}) do
    IO.iodata_to_binary(statement)
  end
end
