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
    handle(message)
    loop(socket)
  end

  defp handle(["rawblock", data, _]) do
    spawn_link(fn ->
      Logger.debug "received block"
      :timer.sleep(1000)
      Logger.debug "parsing block"
      case RawBlock.parse(data) do
        {:ok, block} ->
          Logger.debug "block:\n[hash] #{block.id}"
	  Logger.debug "waiting block"
	  :timer.sleep(1000)
	  Logger.debug "sending to chain"
          {:ok, new_block} = Blockchain.handle_receive_block(block)
          notify_all_confirmations(new_block)
        {:error, reason} ->
          IO.inspect reason
      end
    end)
  end

  defp handle(["rawtx", data, _]) do
    case RawTransaction.parse(data) do
      {:ok, tx, <<>>} ->
        NotificationsController.notify_transaction(tx)
      {:error, reason} ->
        IO.inspect reason
    end
  end

  @spec notify_all_confirmations(pid) :: :ok
  defp notify_all_confirmations(tip) do
    Blockchain.each_block(tip, fn(block, confirmations) ->
      raw_block = block |> LinkedBlock.block
      NotificationsController.notify_block(raw_block, confirmations)
    end)
  end
end
