defmodule Mssqlex.Error do
  @moduledoc """
  Defines an error returned from the ODBC adapter.
  * `message` is the full message returned by ODBC
  * `odbc_code` is an atom representing the returned
    [SQLSTATE](https://docs.microsoft.com/en-us/sql/odbc/reference/appendixes/appendix-a-odbc-error-codes)
    or the string representation of the code if it cannot be translated.
  """

  defexception [:message, :odbc_code, constraint_violations: []]

  @type t :: %__MODULE__{
    message: binary(),
    odbc_code: atom() | binary(),
    constraint_violations: Keyword.t
  }

  @not_allowed_in_transaction_messages [226, 574]

  @doc false
  @spec exception(binary()) :: t()
  def exception({_, _, reason} = message) do
    %__MODULE__{
      message: to_string(to_string reason),
      odbc_code: get_code(message),
      constraint_violations: get_constraint_violations(to_string reason)
    }
  end

  def exception(message) do
    %__MODULE__{
      message: to_string(message)
    }
  end

  defp get_code({odbc_code, native_code, _reason}) do
    cond do
      native_code in @not_allowed_in_transaction_messages ->
        :not_allowed_in_transaction
      odbc_code !== nil ->
        translate(to_string odbc_code)
      true -> :unknown
    end
  end
  defp get_code(_), do: :unknown

  defp translate("42S01"), do: :base_table_or_view_already_exists
  defp translate("42S02"), do: :base_table_or_view_not_found
  defp translate("28000"), do: :invalid_authorization
  defp translate("42000"), do: :syntax_error_or_access_violation
  defp translate(code), do: code

  defp get_constraint_violations(reason) do
    constraint_checks =
      [unique: ~r/Violation of UNIQUE KEY constraint '(\S+?)'./,
       foreign_key: ~r/conflicted with the FOREIGN KEY constraint "(\S+?)"./,
       check: ~r/conflicted with the CHECK constraint "(\S+?)"./]
    extract = fn {key, test}, acc ->
      case Regex.scan(test, reason, capture: :all_but_first) do
        [] -> acc
        matches -> Enum.reduce(matches, acc, fn [match], acc ->
                     [{key, match} | acc] end)
      end
    end
    Enum.reduce(constraint_checks, [], extract)
  end
end
