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
  alias Mssqlex.Query
  alias Mssqlex.Result
  alias Mssqlex.Type

  @spec parse(query :: Query.t(), opts :: Keyword.t()) :: Query.t()
  def parse(query, _opts), do: query

  @spec describe(query :: Query.t(), opts :: Keyword.t()) :: Query.t()
  def describe(query, _opts), do: query

  @spec encode(query :: Query.t(),
    params :: [Type.param()], opts :: Keyword.t()) :: [Type.param()]
  def encode(_query, params, opts) do
    Enum.map(params, &(Type.encode(&1, opts)))
  end

  @spec decode(query :: Query.t(), result :: Result.t(), opts :: Keyword.t()) ::
    Result.t()
  def decode(_query, %Result{rows: rows} = result, opts) when not is_nil(rows) do
    Map.put(result, :rows, Enum.map(rows, fn row -> Enum.map(row, &(Type.decode(&1, opts))) end))
  end
  def decode(_query, result, _opts), do: result
end

defimpl String.Chars, for: Mssqlex.Query do
  def to_string(%Mssqlex.Query{statement: statement}) do
    IO.iodata_to_binary(statement)
  end
end
