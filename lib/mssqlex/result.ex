defmodule Mssqlex.Result do
  @moduledoc """
  Result struct returned from any successful query. Its fields are:
    * `columns` - The names of each column in the result set;
    * `rows` - The result set. A list of tuples, each tuple corresponding to a
                row, each element in the tuple corresponds to a column;
    * `num_rows` - The number of fetched or affected rows;
  """

  @type t :: %__MODULE__{
    columns:  [String.t] | nil,
    rows:     [[term] | binary] | nil,
    num_rows: integer | :undefined}

  defstruct [columns: nil, rows: nil, num_rows: :undefined]
end
