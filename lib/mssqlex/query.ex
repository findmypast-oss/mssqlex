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
  @unicode_types [:sql_wchar, :sql_wvarchar, :sql_wlongvarchar]
  def parse(query, _opts), do: query
  def describe(query, _opts), do: query
  def encode(_query, params, _opts) do
    Enum.map(params, fn {type, values} ->
      {type, Enum.map(values, &(encode_type(type, &1)))} end)
  end
  def decode(_query, result, _opts), do: result

  defp encode_type({string_type, _}, value) when string_type in @unicode_types do
    :unicode.characters_to_binary(value, :unicode, {:utf16, :little})
  end
  defp encode_type(_type, value), do: value
end
