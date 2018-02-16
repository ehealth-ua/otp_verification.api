defmodule Luhn do
  @moduledoc """
  Implemantation of Luhn algorithm. Calculates and verifies a number.
  """

  require Integer

  def verify(number) when is_integer(number) do
    digits = Integer.digits(number)

    {original_number, check_digit} =
      digits
      |> Enum.split(Enum.count(digits) - 1)
      |> Tuple.to_list()
      |> Enum.map(&Enum.reduce(&1, fn d, acc -> acc * 10 + d end))
      |> List.to_tuple()

    calculated = calculate(original_number)

    case calculated do
      {:ok, ^number, ^original_number, ^check_digit} ->
        {:ok, number}

      _ ->
        {:error, number}
    end
  end

  def calculate(number) when is_integer(number) do
    digits = Integer.digits(number)

    odd_sum =
      digits
      |> Enum.take_every(2)
      |> Enum.reduce(fn d, acc -> d + acc end)

    even_sum =
      digits
      |> Enum.drop(1)
      |> Enum.take_every(2)
      |> Enum.map(&(&1 * 2))
      |> Enum.map(fn d -> if(d > 9, do: d - 9, else: d) end)
      |> Enum.reduce(fn d, acc -> d + acc end)

    sum = odd_sum + even_sum
    n = sum * 9

    check_digit =
      n
      |> Integer.digits()
      |> List.last()

    {:ok, number * 10 + check_digit, number, check_digit}
  end
end
