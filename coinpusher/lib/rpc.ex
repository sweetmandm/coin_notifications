defmodule CoinPusher.RPC do
  alias JSONRPC2.Clients.TCP

  def start(host, port) do
    TCP.start(host, port, __MODULE__)
  end

  def get_raw_transaction(hash) do
    TCP.call(__MODULE__, "getrawtransaction", [hash])
  end
end
