defmodule CoinPusher.ZMQRawTx do
  alias CoinPusher.{RawTransaction, NotificationsController}

  def parse(data) do
		case RawTransaction.parse(data) do
      {:ok, tx, <<>>} ->
        NotificationsController.notify_transaction(tx)
      {:error, reason} ->
        IO.inspect reason
    end
  end
end
