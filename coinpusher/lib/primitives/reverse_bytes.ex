defmodule CoinPusher.ReverseBytes do

  @spec reverse_bytes(binary) :: binary
  def reverse_bytes(binary) when is_binary(binary), do: do_reverse(binary, <<>>)

  defp do_reverse(<<>>, acc), do: acc

  defp do_reverse(<< byte :: binary-size(1), rest :: binary >>, acc) do
    do_reverse(rest, byte <> acc)
  end
end
