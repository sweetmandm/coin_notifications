defmodule CoinPusher.BitcoinAddress do
  alias CoinPusher.Base58

  def from(input, type) when byte_size(input) == 20 do
    net = Application.get_env(:coinpusher, :btc_net) || "regtest"
    prefix = prefix_for_net(net, type)
    data = <<prefix :: integer, input :: binary>>
    Base58.encode_check(data)
  end

  defp prefix_for_net(net, :tx_scripthash) do
    if net == nil, do: 5, else: 196
  end

  defp prefix_for_net(net, _type) do
    if net == nil, do: 0, else: 111
  end
end
