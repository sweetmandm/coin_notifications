defmodule CoinPusher.ZMQClient do
  require Logger
  alias CoinPusher.{
    RawTransaction, RawBlock, NotificationsController, Blockchain, LinkedBlock
  }

  def init(address, port) do
    NotificationsController.init()
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

  defp handle(["rawblock", data, _]) do
    case RawBlock.parse(data) do
      {:ok, block} ->
        Logger.debug "block:\n[hash] #{block.id}"
        Blockchain.handle_receive_block(block)
        Blockchain.find_block(fn(block) ->
          NotificationsController.notify_block(block |> LinkedBlock.block)
          false
        end)
      {:error, reason} ->
        IO.inspect reason
    end
  end

  defp handle(["rawtx", data, _]) do
    case RawTransaction.parse(data) do
      {:ok, tx, <<>>} ->
        NotificationsController.notify_transaction(tx)
      {:error, reason} ->
        IO.inspect reason
    end
  end
end
