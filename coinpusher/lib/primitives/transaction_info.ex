defmodule CoinPusher.TransactionInfo do
  alias CoinPusher.{RawTransaction, TxOut}

  @type address_tx :: %{value: integer, addresses: list(String.t)}

  defstruct [:id, :destinations]

  @spec from(%RawTransaction{}) :: %__MODULE__{}
  def from(tx) do
    %__MODULE__{
      id: tx.id,
      destinations: destinations(tx)
    }
  end

  @spec destinations(%RawTransaction{}) :: address_tx
  def destinations(tx) do
    tx.tx_out |> Enum.map(fn(output) ->
      %{
        value: output.value,
        addresses: output |> TxOut.destinations
      }
    end)
  end

  @spec all_addresses(%__MODULE__{}) :: list(String.t)
  def all_addresses(info) do
    info.destinations
    |> Enum.map(&(&1[:addresses]))
  end

  def get_full_inputs(_tx) do
    []
    # So it turns out making an RPC call for each input will not be fast
    # enough. This means we cannot determine the transaction input addresses
    # without some alternate strategy that likely makes this project moot,
    # such as indexing all blockchain transactions in a database.
    #
    # tx.tx_in
    # |> Enum.reject(&TxIn.is_coinbase?/1)
    # |> Enum.map(fn(tx_in) ->
    #   tx_id = tx_in.previous_output.hash |> TxId.to_string
    #   case CoinPusher.RPC.get_raw_transaction(tx_id) do
    #     {:ok, %{"result" => result}} ->
    #       {:ok, raw_tx} = result |> Base.decode16(case: :lower)
    #       {:ok, tx, <<>>} = raw_tx |> RawTransaction.parse
    #       tx.tx_out |> Enum.at(tx_in.previous_output.index)
    #     {:error, :internal_server_error} ->
    #       []
    #     _ ->
    #       []
    #   end
    # end)
    # |> List.flatten
  end
end

defimpl Inspect, for: CoinPusher.TransactionInfo do
  import Inspect.Algebra
  def inspect(info, _opts) do
    dests = multiline(info.destinations)
    concat ["tx: #{info.id}\n",
            "[destinations] #{dests}"]
  end

  defp multiline(list) do
    list
    |> Enum.map(fn(source) -> inspect(source) end)
    |> Enum.join("\n               ")
  end
end
