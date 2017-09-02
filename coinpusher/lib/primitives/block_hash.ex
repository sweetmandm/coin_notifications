defmodule CoinPusher.BlockHash do
  import CoinPusher.ReverseBytes

  @spec to_string(binary) :: String.t
  def to_string(binary) do
    binary
    |> sha256
    |> sha256
    |> reverse_bytes
    |> Base.encode16(case: :lower)
  end

  defp sha256(data) do
    :crypto.hash(:sha256, data)
  end
end
