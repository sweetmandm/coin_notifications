defmodule CoinPusher.DoubleSha256 do
  import CoinPusher.ReverseBytes

  def double_sha256(binary) when is_binary(binary) do
    binary
    |> sha256
    |> sha256
  end

  @spec to_string(binary) :: String.t
  def to_string(binary) when is_binary(binary) do
    binary
    |> double_sha256
    |> reverse_bytes
    |> Base.encode16(case: :lower)
  end

  defp sha256(data) do
    :crypto.hash(:sha256, data)
  end
end
