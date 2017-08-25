defmodule CoinPusher.AddressListeners do
  alias CoinPusher.Contact

  @spec init(atom) :: atom
  def init(table_name) do
    :ets.new(table_name, [:named_table, :set])
  end

  @spec add(atom, String.t, String.t) :: boolean
  def add(table_name, address, phone) when is_binary(phone) do
    contact = %Contact{phone_number: phone}
    add(table_name, address, contact)
  end

  @spec add(atom, String.t, %Contact{}) :: boolean
  def add(table_name, address, contact) do
    list = case :ets.lookup(table_name, address) do
      [{^address, contacts} | _] -> [contact |contacts]
      [] -> [contact]
    end
    :ets.insert(table_name, {address, list})
  end

  @spec lookup(atom, String.t) :: list({String.t, list(%Contact{})})
  def lookup(table_name, address) do
    :ets.lookup(table_name, address)
  end
end
