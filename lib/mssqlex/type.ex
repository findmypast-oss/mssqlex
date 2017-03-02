defmodule Mssqlex.Type do

  def encode(value) when is_boolean(value), do: {:sql_bit, [value]}
  def encode({year, month, day} = date) do
    encoded = Date.from_erl!(date)
    |> to_string
    |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end
  def encode({hour, minute, sec, usec} = date) do
    precision = if usec == 0, do: 0, else: 6
    encoded = Time.from_erl!({hour, minute, sec}, {usec, precision})
    |> to_string
    |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end
  def encode({{year, month, day}, {hour, minute, sec, usec}}) do
    precision = if usec == 0, do: 0, else: 6
    encoded = NaiveDateTime.from_erl!({{year, month, day}, {hour, minute, sec}}, {usec, precision})
    |> to_string
    |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end
  def encode(value) when is_integer(value) do
    {:sql_integer, [value]}
  end
  def encode(value) when is_float(value) do
    encoded = value |> to_string |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end
  def encode(%Decimal{} = value) do
    encoded = value |> to_string |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end
  def encode(value) when is_binary(value) do
    case :unicode.characters_to_binary(value, :unicode, :latin1) do
      {_, _, _} ->
        utf16 = :unicode.characters_to_binary(value, :unicode, {:utf16, :little})
        {{:sql_wvarchar, String.length(utf16)}, [utf16]}
      encoded ->
        latin1 = to_charlist(encoded)
        {{:sql_varchar, length(latin1)}, [latin1]}
    end
  end
  def encode(value), do: raise "Could not parse param: #{inspect value}. Unrecognised type."

  def decode(value) when is_float(value), do: Decimal.new(value)
  def decode(value) when is_binary(value) do
    :unicode.characters_to_binary(value, {:utf16, :little})
  end
  def decode(value) when is_list(value), do: to_string(value)
  def decode(value), do: value
end
