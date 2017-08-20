defmodule CoinPusher.ZMQClient do
  require Logger
  require Base58
  alias CoinPusher.RawTransaction
  alias CoinPusher.StandardTx
  require IEx

  def init(address, port) do
    pid = spawn_listener(address, port)
    {:ok, pid}
  end

  def spawn_listener(address, port) do
    spawn_link(fn ->
      start_listen(address, port)
    end)
  end

  def start_listen(address, port) do
    Logger.info "[ZMQ] Subscribing to #{address}:#{port}"
    {:ok, socket} = :chumak.socket(:sub)
    subscribe(socket)
    {:ok, _pid} = :chumak.connect(socket, :tcp, address, port)
    loop(socket)
  end

  defp subscribe(socket) do
    :chumak.subscribe(socket, 'rawblock')
    :chumak.subscribe(socket, 'rawtx')
  end

  defp loop(socket) do
    {:ok, message} = :chumak.recv_multipart(socket)
    handle(message)
    loop(socket)
  end

  defp handle(["rawblock", _data, _]) do
  end

  defp handle(["rawtx", data, _]) do
    case RawTransaction.parse(data) do
      {:ok, tx} ->
        out = tx.tx_out |> Enum.at(0)
        script = out.pk_script
        destinations = StandardTx.extract_destinations(script)
        {:ok, _, dests, _} = destinations
        addresses = dests |> Enum.map(&BitcoinAddress.from/1)
        Logger.info "[parsed rawtx] #{addresses}"
        {:ok, addresses}
      {:error, reason} ->
        IO.inspect reason
    end
  end
end
