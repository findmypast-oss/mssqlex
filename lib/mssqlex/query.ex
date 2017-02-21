defmodule Mssqlex.Query do

  @type t :: %__MODULE__{
    name: iodata,
    statement: iodata,
  }

  defstruct [:name, :statement]
end

defimpl DBConnection.Query, for: Mssqlex.Query do
  def parse(query, _opts), do: query
  def describe(query, _opts), do: query
  def encode(query, _params, _opts), do: query
  def decode(_query, result, _opts), do: result
end
