defmodule Mssqlex.Result do
  @moduledoc """
  Result struct returned from any successful query. Its fields are:
    * `rows` - The result set. A list of tuples, each tuple corresponding to a
                row, each element in the tuple corresponds to a column;
    * `num_rows` - The number of fetched or affected rows;
  """

  @type t :: %__MODULE__{
    rows:     [[term] | binary] | nil,
    num_rows: integer | :undefined}

  defstruct [:rows, num_rows: :undefined]
end
