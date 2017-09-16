defmodule CoinPusher.ZMQRawBlock do
  require Logger
  alias CoinPusher.{RawBlock, Blockchain, NotificationsController, LinkedBlock}

  def parse(data) do
    case RawBlock.parse(data) do
      {:ok, block} ->
        Logger.debug "block:\n[hash] #{block.id}"
        {:ok, new_block} = Blockchain.handle_receive_block(block)
        notify_all_confirmations(new_block)
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
