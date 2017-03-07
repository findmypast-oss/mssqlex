defmodule Mssqlex.Type do
  @moduledoc """
  Type conversions.
  """

  @typedoc "Input param."
  @type param :: bitstring()
    | number()
    | date()
    | time()
    | datetime()
    | Decimal.t()

  @typedoc "Output value."
  @type return_value :: bitstring()
    | integer()
    | date()
    | datetime()
    | Decimal.t()

  @typedoc "Date as `{year, month, day}`" 
  @type date :: {1..9_999, 1..12, 1..31}

  @typedoc "Time as `{hour, minute, sec, usec}`"
  @type time :: {0..24, 0..60, 0..60, 0..999_999}

  @typedoc "Datetime"
  @type datetime :: {date(), time()}

  @doc """
  Transforms input params into `:odbc` params.
  """
  @spec encode(value :: param(), opts :: Keyword.t) ::
    {:odbc.odbc_data_type(), [:odbc.value()]}
  def encode(value, _) when is_boolean(value) do
    {:sql_bit, [value]}
    end

  def encode({_year, _month, _day} = date, _) do
    encoded = Date.from_erl!(date)
    |> to_string
    |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end

  def encode({hour, minute, sec, usec}, _) do
    precision = if usec == 0, do: 0, else: 6
    encoded = Time.from_erl!({hour, minute, sec}, {usec, precision})
    |> to_string
    |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end

  def encode({{year, month, day}, {hour, minute, sec, usec}}, _) do
    precision = if usec == 0, do: 0, else: 6
    encoded = NaiveDateTime.from_erl!(
      {{year, month, day}, {hour, minute, sec}}, {usec, precision})
    |> to_string
    |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end

  def encode(value, _) when is_integer(value)
  and (value > -1_000_000_000)
  and (value < 1_000_000_000) do
    {:sql_integer, [value]}
  end

  def encode(value, _) when is_integer(value) do
    encoded = value |> to_string |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end

  def encode(value, _) when is_float(value) do
    encoded = value |> to_string |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end

  def encode(%Decimal{} = value, _) do
    encoded = value |> to_string |> to_charlist
    {{:sql_varchar, length(encoded)}, [encoded]}
  end

  def encode(value, _) when is_binary(value) do
    case :unicode.characters_to_binary(value, :unicode, :latin1) do
      {_, _, _} ->
        with utf16 when is_bitstring(utf16) <-
          :unicode.characters_to_binary(value, :unicode, {:utf16, :little})
        do
          {{:sql_wvarchar, String.length(utf16)}, [utf16]}
        else
          _ -> raise %Mssqlex.Error{
            message: "failed to convert string to UTF16LE"}
        end
      encoded ->
        latin1 = to_charlist(encoded)
        {{:sql_varchar, length(latin1)}, [latin1]}
    end
  end

  def encode(value, _) do
    raise %Mssqlex.Error{
      message: "could not parse param #{inspect value} of unrecognised type."}
  end

  @doc """
  Transforms `:odbc` return values to Elixir representations.
  """
  @spec decode(:odbc.value(), opts :: Keyword.t) :: return_value()
  def decode({{_year, _month, _day}, {_hour, _minute, _sec}} = datetime, _) do
    NaiveDateTime.from_erl!(datetime, {0, 6})
  end

  def decode(value, _) when is_float(value) do
    Decimal.new(value)
  end

  def decode(value, opts) when is_binary(value) do
    if opts[:preserve_encoding] do
      value
    else
      :unicode.characters_to_binary(value, {:utf16, :little})
    end
  end

  def decode(value, _) when is_list(value) do
    to_string(value)
  end

  def decode(value, _) do
    value
  end
end
