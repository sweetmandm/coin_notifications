defmodule CoinPusher.NotificationsController do
  require Logger
  alias CoinPusher.{
    RawTransaction, AddressListeners, Contact, TransactionInfo, Blockchain
  }

  @satoshis_per_btc 100000000

  def init do
    AddressListeners.init()
  end

  @spec add_listener(String.t, %Contact{} | String.t, list(integer)) :: :ok
  def add_listener(address, contact, confirmation_triggers) do
    AddressListeners.add(address, contact, confirmation_triggers)
  end

  @spec notify(%RawTransaction{}) :: pid
  def notify(transaction) do
    spawn(fn -> send_notifications!(transaction) end)
  end

  @spec send_notifications!(%RawTransaction{}) :: :ok
  defp send_notifications!(transaction) do
    info = TransactionInfo.from(transaction)
    confirmations = transaction |> Blockchain.confirmations_for_transaction
    Logger.debug "#{inspect(info)}"

    info.sources |> Enum.each(fn(source) ->
      send_notifications_for_source!(transaction, source, confirmations)
    end)

    info.destinations |> Enum.each(fn(dest) ->
      send_notifications_for_dest!(transaction, dest, confirmations)
    end)

    AddressListeners.did_notify(transaction.id, confirmations)
  end

  @spec send_notifications_for_source!(%TransactionInfo{}, %{}, integer) :: :ok
  defp send_notifications_for_source!(tx, source, confirmations) do
    value = source[:value] / @satoshis_per_btc
    send_notification!(
      source[:addresses],
      "Sending #{value} BTC in tx #{tx.id} with #{confirmations} confirmations",
      confirmations
    )
  end

  @spec send_notifications_for_dest!(%TransactionInfo{}, %{}, integer) :: :ok
  defp send_notifications_for_dest!(tx, dest, confirmations) do
    value = dest[:value] / @satoshis_per_btc
    send_notification!(
      dest[:addresses],
      "Receiving #{value} BTC in tx #{tx.id} with #{confirmations} confirmations",
      confirmations
    )
  end

  @spec send_notification!(list(String.t), String.t, integer) :: :ok
  defp send_notification!(addresses, message, confirmations) do
    addresses |> Enum.each(fn(address) ->
      case AddressListeners.lookup(address, confirmations) do
        list when is_list(list) ->
          list
          |> Enum.each(&Contact.notify(&1, message))
        _ ->
          :no_listeners
      end
    end)
  end
end
