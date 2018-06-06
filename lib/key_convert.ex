defmodule KeyConvert do
  @moduledoc """
  KeyConvert allows transforming the keys of maps to another case.

  `Atom` keys will be converted to `String`s as atoms are not
  garbage-collected and are not meant for dynamically generated data.

  It supports nested maps.
  """

  @doc """
  Converts the keys to snake case.

  ## Examples

      iex> KeyConvert.snake_case(%{totalAmount: 500})
      %{"total_amount" => 500}

      iex> KeyConvert.snake_case(%{
      ...>   contactInfo: %{emailAddress: "email@example.com"}
      ...> })
      %{"contact_info" => %{"email_address" => "email@example.com"}}
  """
  def snake_case(map) when is_map(map) do
    convert(map, &do_snake_case/1)
  end

  defp do_snake_case(atom) when is_atom(atom) do
    atom |> to_string() |> do_snake_case()
  end

  defp do_snake_case(string) when is_binary(string) do
    string
    |> String.split(".")
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end

  defp do_snake_case(key), do: key

  @doc """
  Converts the keys to camel case.

  ## Examples

      iex> KeyConvert.camelize(%{total_amount: 500})
      %{"totalAmount" => 500}

      iex> KeyConvert.camelize(%{
      ...>   contact_info: %{email_address: "email@example.com"}
      ...> })
      %{"contactInfo" => %{"emailAddress" => "email@example.com"}}
  """
  def camelize(map) when is_map(map) do
    convert(map, &do_camelize/1)
  end

  defp do_camelize(atom) when is_atom(atom) do
    atom |> to_string() |> do_camelize()
  end

  defp do_camelize(string) when is_binary(string) do
    tail = string |> Macro.camelize() |> String.slice(1..-1)
    String.first(string) <> tail
  end

  defp do_camelize(key), do: key

  @doc """
  Renames the keys based on `rename_map` as lookup.

  Keys not included in `rename_map` will not be changed.

  ## Examples

      iex> KeyConvert.rename(
      ...>   %{amount: 500, currency: "PHP"},
      ...>   %{amount: :value}
      ...> )
      %{value: 500, currency: "PHP"}
  """
  def rename(map, rename_map) when is_map(map) and is_map(rename_map) do
    convert(map, fn key -> rename_map[key] || key end)
  end

  @doc """
  Converts the keys based on `converter` function provided.

  Converter function should be able to take a key as an input and return a new
  key which will be used for the converted `Map`.

  ## Examples

      iex> append_change = fn key -> key <> ".changed" end
      iex> KeyConvert.convert(%{"total_amount" => 500}, append_change)
      %{"total_amount.changed" => 500}
  """
  def convert(map, converter) when is_map(map) and is_function(converter, 1) do
    for {key, value} <- map, into: %{} do
      new_key = converter.(key)
      case is_map(value) do
        true -> {new_key, convert(value, converter)}
        false -> {new_key, value}
      end
    end
  end
end
