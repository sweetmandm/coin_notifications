defmodule CoinPusher.TransactionInfo do
  alias CoinPusher.{RawTransaction, TxOut, TxIn, TxId, RPC}

  @type address_tx :: %{value: integer, addresses: list(String.t)}

  defstruct [:raw_transaction, :destinations, :sources]

  @spec from(%RawTransaction{}) :: %__MODULE__{}
  def from(tx) do
    %__MODULE__{
      raw_transaction: tx,
      sources: sources(tx),
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

  @spec sources(%RawTransaction{}) :: address_tx
  def sources(tx) do
    tx
    |> get_full_inputs
    |> Enum.map(fn(input) ->
      %{
        value: input.value,
        addresses: input |> TxOut.destinations
      }
    end)
  end

  def get_full_inputs(tx) do
    tx.tx_in
    |> Enum.reject(&TxIn.is_coinbase?/1)
    |> Enum.map(fn(tx_in) ->
      tx_id = tx_in.previous_output.hash |> TxId.to_string
      case RPC.get_raw_transaction(tx_id) do
        {:ok, %{"result" => result}} ->
          {:ok, raw_tx} = result |> Base.decode16(case: :lower)
          {:ok, tx, <<>>} = raw_tx |> RawTransaction.parse
          tx.tx_out |> Enum.at(tx_in.previous_output.index)
        {:error, :internal_server_error} ->
          []
      end
    end)
    |> List.flatten
  end
end

defimpl Inspect, for: CoinPusher.TransactionInfo do
  import Inspect.Algebra
  def inspect(info, _opts) do
    sources = multiline(info.sources )
    dests = multiline(info.destinations)
    concat ["tx:\n",
            "[sources]      #{sources}\n",
            "[destinations] #{dests}"]
  end

  defp multiline(list) do
    list
    |> Enum.map(fn(source) -> inspect(source) end)
    |> Enum.join("\n               ")
  end
end
