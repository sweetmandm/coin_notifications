defmodule BitcoinAddress do
  def from(input) when byte_size(input) == 20 do
    net = Application.get_env(:coinpusher, :btc_net) || "regtest"
    prefix = prefix_for_net(net)
    data = <<prefix :: integer, input :: binary>>
    Base58.encode_check(data)
  end

  defp prefix_for_net(net) do
    if net == nil, do: 0, else: 111
  end
end
