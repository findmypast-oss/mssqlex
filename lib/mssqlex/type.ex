defmodule Mssqlex.Type do
  require Logger

  @moduledoc """
  Type conversions.

  Note the :odbc return types for decoding can be found here:
  http://erlang.org/doc/apps/odbc/databases.html#data-types-
  """

  @typedoc "Input param."
  @type param ::
          bitstring()
          | number()
          | date()
          | time()
          | datetime()
          | Decimal.t()

  @typedoc "Output value."
  @type return_value ::
          bitstring()
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
  @spec encode(value :: param(), opts :: Keyword.t()) ::
          {:odbc.odbc_data_type(), [:odbc.value()]}
  def encode(value, _) when is_boolean(value) do
    {:sql_bit, [value]}
  end

  def encode({_year, _month, _day} = date, _) do
    encoded =
      Date.from_erl!(date)
      |> to_string
      |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode({hour, minute, sec, usec}, _) do
    precision = if usec == 0, do: 0, else: 6

    encoded =
      Time.from_erl!({hour, minute, sec}, {usec, precision})
      |> to_string
      |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode({{year, month, day}, {hour, minute, sec, usec}}, _) do
    precision = if usec == 0, do: 0, else: 6

    encoded =
      NaiveDateTime.from_erl!(
        {{year, month, day}, {hour, minute, sec}},
        {usec, precision}
      )
      |> to_string
      |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%NaiveDateTime{} = datetime, _) do
    encoded =
      datetime
      |> to_string
      |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%DateTime{} = datetime, _) do
    encoded =
      datetime
      |> to_string
      |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%Date{} = date, _) do
    encoded =
      date
      |> to_string
      |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(value, _)
      when is_integer(value) and value > -1_000_000_000 and
             value < 1_000_000_000 do
    {:sql_integer, [value]}
  end

  def encode(value, _) when is_integer(value) do
    encoded =
      value
      |> to_string
      |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(value, _) when is_float(value) do
    encoded =
      value |> to_string |> :unicode.characters_to_binary(:unicode, :latin1)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%Decimal{} = value, _) do
    encoded =
      value |> to_string |> :unicode.characters_to_binary(:unicode, :latin1)

    precision = Decimal.get_context().precision
    scale = calculate_decimal_scale(value)

    # precision = value.coef |> Integer.digits() |> Enum.count()
    # scale = precision + value.exp - 1

    odbc_data_type = {:sql_decimal, precision, scale}
    {odbc_data_type, [encoded]}
  end

  def encode(value, _) when is_binary(value) do
    utf16 = :unicode.characters_to_binary(value, :unicode, {:utf16, :little})

    cond do
      # string
      is_bitstring(utf16) ->
        {{:sql_wvarchar, byte_size(value)}, [utf16]}

      # uuid
      byte_size(value) == 16 ->
        <<u0::32, u1::16, u2::16, u3::16, u4::48>> = value

        value =
          [<<u0::32>>, <<u1::16>>, <<u2::16>>, <<u3::16>>, <<u4::48>>]
          |> Enum.map(&Base.encode16/1)
          |> Enum.join("-")

        {{:sql_char, 36}, [value]}

      true ->
        raise %Mssqlex.Error{
          message: "failed to convert string to UTF16LE. "
        }
    end
  end

  def encode(nil, _) do
    {:sql_integer, [:null]}
  end

  # def encode(values, v) when is_list(values), do: Enum.map(values, &encode(&1, v))

  def encode(value, _) do
    raise %Mssqlex.Error{
      message: "could not parse param #{inspect(value)} of unrecognised type."
    }
  end

  @doc """
  Transforms `:odbc` return values to Elixir representations.
  """
  @spec decode(:odbc.value(), opts :: Keyword.t()) :: return_value()

  def decode(value, _) when is_float(value) do
    Decimal.from_float(value)
  end

  def decode(value, opts) when is_binary(value) do
    cond do
      # string
      not (opts[:preserve_encoding] || String.printable?(value)) ->
        :unicode.characters_to_binary(value, {:utf16, :little}, :unicode)

      # uuid
      String.match?(
        value,
        ~r/\b[0-9A-F]{8}\b-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-\b[0-9A-F]{12}\b/
      ) ->
        value
        |> String.split("-")
        |> Enum.map(&Base.decode16!/1)
        |> Enum.join()

      # I don't think this should ever happen
      true ->
        value
    end
  end

  def decode(value, _) when is_list(value) do
    to_string(value)
  end

  def decode(:null, _) do
    nil
  end

  def decode({date, {h, m, s}}, opts) do
    decode({date, {h, m, s, 0}}, opts)
  end

  def decode({{year, month, day}, {hour, minute, second, msecond}}, _) do
    {:ok, date} = Date.new(year, month, day)
    # microsecond or milisecond?
    {:ok, time} = Time.new(hour, minute, second, msecond)
    {:ok, datetime} = NaiveDateTime.new(date, time)
    datetime
  end

  def decode(value, _) do
    value
  end

  defp calculate_decimal_scale(dec) do
    coef_size = dec.coef |> Integer.digits() |> Enum.count()
    coef_size + dec.exp - 1
  end
end
