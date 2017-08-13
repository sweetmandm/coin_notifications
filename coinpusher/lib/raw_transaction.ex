# https://en.bitcoin.it/wiki/Protocol_documentation#tx
defmodule CoinPusher.RawTransaction do
  alias CoinPusher.VarInt

  defstruct [:version, :tx_in_count]

  def parse(data) do
    <<version :: signed-integer-little-32, rest :: binary >> = data
    tx = parse(version, rest)
    {:ok, tx}
  end

  defp parse(version = 2, data) do
    {:ok, tx_in_count, _rest} = VarInt.parse(data)
    %CoinPusher.RawTransaction{
      version: version,
      tx_in_count: tx_in_count
    }
  end
end
