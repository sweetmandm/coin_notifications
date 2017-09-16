defmodule CoinPusher.NotificationsController do
  require Logger
  alias CoinPusher.{
    RawTransaction, RawBlock, AddressListeners, Contact, TransactionInfo, Blockchain
  }

  @satoshis_per_btc 100000000

  def init do
    AddressListeners.init()
  end

  @spec add_listener(String.t, %Contact{} | String.t, list(integer)) :: :ok
  def add_listener(address, contact, confirmation_triggers) do
    AddressListeners.add(address, contact, confirmation_triggers)
  end

  @spec notify_transaction(%RawTransaction{}) :: pid
  def notify_transaction(transaction) do
    info = TransactionInfo.from(transaction)
    send_notifications!(info)
  end

  @spec notify_block(%RawBlock{}, integer) :: pid
  def notify_block(block, confirmations) do
    block.transaction_infos
    |> Enum.each(&(__MODULE__.send_notifications!(&1, confirmations)))
  end

  @spec send_notifications!(%TransactionInfo{}) :: :ok
  def send_notifications!(transaction) do
    confirmations = transaction.id |> Blockchain.confirmations_for_transaction
    send_notifications!(transaction, confirmations)
  end

  @spec send_notifications!(%TransactionInfo{}, integer) :: :ok
  def send_notifications!(info, confirmations) do
    info.sources |> Enum.each(fn(source) ->
      send_notifications_for_source!(info, source, confirmations)
    end)

    info.destinations |> Enum.each(fn(dest) ->
      send_notifications_for_dest!(info, dest, confirmations)
    end)

    AddressListeners.did_notify(info, info.id, confirmations)
  end

  @spec send_notifications_for_source!(%TransactionInfo{}, %{}, integer) :: :ok
  defp send_notifications_for_source!(tx, source, confirmations) do
    value = source[:value] / @satoshis_per_btc
    send_notification!(
      source[:addresses],
      tx.id,
      "Sending #{value} BTC in tx #{tx.id} with #{confirmations} confirmations",
      confirmations
    )
  end

  @spec send_notifications_for_dest!(%TransactionInfo{}, %{}, integer) :: :ok
  defp send_notifications_for_dest!(tx, dest, confirmations) do
    value = dest[:value] / @satoshis_per_btc
    send_notification!(
      dest[:addresses],
      tx.id,
      "Receiving #{value} BTC in tx #{tx.id} with #{confirmations} confirmations",
      confirmations
    )
  end

  @spec send_notification!(list(String.t), String.t, String.t, integer) :: :ok
  defp send_notification!(addresses, txid, message, confirmations) do
    addresses |> Enum.each(fn(address) ->
      case AddressListeners.lookup(address, txid, confirmations) do
        list when is_list(list) ->
          list
          |> Enum.each(&Contact.notify(&1, message))
        _ ->
          :no_listeners
      end
    end)
  end
end
