defmodule CoinPusher.AddressListeners do
  alias CoinPusher.Contact
  alias :mnesia, as: Mnesia

  @spec init() :: :ok
  def init() do
    Mnesia.create_schema([node()])
    Mnesia.start()
    Mnesia.create_table(TxEvent, [attributes: [
      :tx_id, :confirmation
    ]])
    Mnesia.add_table_index(TxEvent, :tx_id)
    Mnesia.create_table(AddressContact, [attributes: [
      :address, :contacts
    ]])
    Mnesia.add_table_index(AddressContact, :address)
    :ok
  end

  @spec add(String.t, String.t, integer) :: boolean
  def add(address, phone, confirmation_triggers) when is_binary(phone) do
    contact = %Contact{phone_number: phone}
    add(address, contact, confirmation_triggers)
  end

  @spec add(String.t, %Contact{}, list(integer)) :: boolean
  def add(address, contact, confirmation_triggers) do
    {:atomic, result} = Mnesia.transaction(fn ->
      Mnesia.read({AddressContact, address})
    end)
    contacts = result |> Enum.flat_map(&(&1 |> elem(2)))
    Mnesia.transaction(fn ->
      Mnesia.write({AddressContact, address, [{contact, confirmation_triggers} | contacts]})
    end)
  end

  @spec lookup(String.t, integer) :: list(%Contact{})
  def lookup(address, confirmations) do
    {:atomic, contacts} = Mnesia.transaction(fn ->
      Mnesia.select(AddressContact, [
        {
          {AddressContact, :"$1", :"$2"},
          [{:==, :"$1", address}],
          [:"$2"]
        }
      ])
    end)
    contacts
    |> List.flatten
    |> Enum.filter(&(&1 |> elem(1) |> Enum.member?(confirmations)))
    |> Enum.map(&(elem(&1, 0)))
  end
end
