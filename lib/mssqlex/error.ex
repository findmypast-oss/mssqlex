defmodule Mssqlex.Error do
  @moduledoc """
  Defines an error returned from the ODBC adapter.
  * `message` is the full message returned by ODBC
  * `odbc_code` is an atom representing the returned [SQLSTATE](https://docs.microsoft.com/en-us/sql/odbc/reference/appendixes/appendix-a-odbc-error-codes)
  or the string representation of the code if it cannot be translated.
  """
  defexception [:message, :odbc_code]

  @type t :: %__MODULE__{
    message: binary(),
    odbc_code: atom() | binary()
  }

  @spec exception(binary()) :: t()
  def exception(message) do
    %__MODULE__{
      message: message,
      odbc_code: get_code(message)
    }
  end

  defp get_code(message) do
    case Regex.run(~r/SQLSTATE IS: (.{5})/, message) do
      nil -> :unknown
      [_, code_string] -> translate(code_string)
    end
  end

  defp translate("42S01"), do: :base_table_or_view_already_exists
  defp translate("42S02"), do: :base_table_or_view_not_found
  defp translate("28000"), do: :invalid_authorization
  defp translate(code), do: code

end
