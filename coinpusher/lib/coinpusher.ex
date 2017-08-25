defmodule CoinPusher.ZMQClient do
  require Logger
  alias CoinPusher.{RawTransaction, NotificationsController}

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
    spawn_link(fn -> handle(message) end)
    loop(socket)
  end

  defp handle(["rawblock", _data, _]) do
  end

  defp handle(["rawtx", data, _]) do
    case RawTransaction.parse(data) do
      {:ok, tx} ->
        NotificationsController.notify(tx)
      {:error, reason} ->
        IO.inspect reason
    end
  end
end
