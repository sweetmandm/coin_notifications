defmodule CoinPusher.TxId do
  import CoinPusher.ReverseBytes

  @spec to_string(binary) :: String.t
  def to_string(binary) do
    binary
    |> reverse_bytes
    |> Base.encode16(case: :lower)
  end

  @spec from_string(String.t) :: binary
  def from_string(transaction_id) do
    transaction_id
    |> Base.decode16(case: :lower)
    |> reverse_bytes
  end

  @spec parse(binary) :: {:ok, binary, binary}
  def parse(data) do
    <<id :: binary-size(32), rest :: binary>> = data
    {:ok, id, rest}
  end
end
