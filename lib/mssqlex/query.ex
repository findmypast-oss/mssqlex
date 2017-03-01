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

  @unicode_types [:sql_wchar, :sql_wvarchar, :sql_wlongvarchar]
  @numeric_types [:sql_numeric, :sql_decimal]

  def parse(query, _opts), do: query
  def describe(query, _opts), do: query
  def encode(_query, params, _opts) do
    Enum.map(params, fn {type, values} ->
      {type, Enum.map(values, &(encode_type(type, &1)))} end)
  end

  def decode(_query, %Result{rows: rows} = result, _opts) when not is_nil(rows) do
    Map.put(result, :rows, Enum.map(rows, fn row -> Enum.map(row, &decode_cell/1) end))
  end
  def decode(_query, result, _opts), do: result

  def decode_cell(value) when is_list(value) do
    IO.iodata_to_binary value
  end
  def decode_cell(value), do: value

  defp encode_type({string_type, _}, value) when string_type in @unicode_types do
    :unicode.characters_to_binary(value, :unicode, {:utf16, :little})
  end

  defp encode_type({numeric_type, precision, scale}, value)
  when numeric_type in @numeric_types
  and precision >= 0 and precision <= 9
  and scale == 0
  do
    {integer, ""} = Integer.parse(value)
    integer
  end

  defp encode_type({numeric_type, precision, scale}, value)
  when numeric_type in @numeric_types
  and ((precision >= 10 and precision <= 15 and scale == 0)
      or (scale <= 15 and scale > 0))
  do
    {float, ""} = Float.parse(value)
    float
  end

  defp encode_type(_, value) when is_binary(value) do
    to_charlist(value)
  end

  defp encode_type(_type, value), do: value
end
