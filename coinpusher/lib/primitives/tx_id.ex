defmodule CoinPusher.TxId do

  @spec to_string(binary) :: String.t
  def to_string(binary) do
    binary
    |> reverse
    |> Base.encode16(case: :lower)
  end

  @spec from_string(String.t) :: binary
  def from_string(transaction_id) do
    transaction_id
    |> Base.decode16(case: :lower)
    |> reverse 
  end

  @spec reverse(binary) :: binary
  defp reverse(binary) when is_binary(binary), do: do_reverse(binary, <<>>)
  defp do_reverse(<<>>, acc), do: acc
  defp do_reverse(<< x :: binary-size(1), bin :: binary >>, acc), do: do_reverse(bin, x <> acc)
end
