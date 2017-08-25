defmodule CoinPusher.NotificationsController do
  use GenServer
  require Logger
  alias CoinPusher.{RawTransaction, AddressListeners, Contact, TransactionInfo}
  require IEx

  def init(listener_table_name) do
    state = AddressListeners.init(listener_table_name)
    {:ok, state}
  end

  @spec start_link(String.t) :: {:ok, pid}
  def start_link(listener_table_name) do
    GenServer.start_link(__MODULE__, listener_table_name, name: __MODULE__)
  end

  @spec add_listener(String.t, %Contact{} | String.t) :: any
  def add_listener(address, contact) do
    GenServer.call(__MODULE__, {:add_listener, address, contact})
  end

  @spec notify(%RawTransaction{}) :: {:reply, :ok, atom}
  def notify(transaction) do
    GenServer.call(__MODULE__, {:notify, transaction})
  end

  def handle_call({:add_listener, address, contact}, _from, state) do
    AddressListeners.add(state, address, contact)
    {:reply, :ok, state}
  end

  def handle_call({:notify, transaction}, _from, state) do
    spawn(fn -> send_notifications!(transaction, state) end)
    {:reply, :ok, state}
  end

  defp send_notifications!(transaction, state) do
    info = TransactionInfo.from(transaction)
    Logger.debug "#{inspect(info)}"

    info.sources |> Enum.each(fn(source) ->
      send_notifications_for_source!(transaction, source, state)
    end)

    info.destinations |> Enum.each(fn(dest) ->
      send_notifications_for_dest!(transaction, dest, state)
    end)
  end

  defp send_notifications_for_source!(_tx, source, state) do
    send_notification!(source[:addresses], "Sending #{source[:value]} Satoshis", state)
  end

  defp send_notifications_for_dest!(_tx, dest, state) do
    send_notification!(dest[:addresses], "Receiving #{dest[:value]} Satoshis", state)
  end

  defp send_notification!(addresses, message, state) do
    addresses |> Enum.each(fn(address) ->
      case AddressListeners.lookup(state, address) do
        [{^address, contacts} | _] ->
          contacts |> Enum.each(&Contact.notify(&1, message))
        _ ->
          :no_listeners
      end
    end)
  end
end
