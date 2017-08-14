# https://en.bitcoin.it/wiki/Protocol_documentation#tx
defmodule CoinPusher.RawTransaction do
  alias CoinPusher.{VarInt, TxIn}

  defstruct [:version, :tx_in]

  def parse(data) do
    <<version :: signed-integer-little-32, rest :: binary >> = data
    tx = parse(version, rest)
    {:ok, tx}
  end

  defp parse(version = 2, data) do
    {:ok, tx_in_count, data} = VarInt.parse(data)
    {:ok, tx_in_list, _data} = parse_tx_in_list([], 0, tx_in_count, data)
    %CoinPusher.RawTransaction{
      version: version,
      tx_in: tx_in_list
    }
  end

  defp parse_tx_in_list(tx_in_list, max, max, data) do
    {:ok, tx_in_list, data}
  end

  defp parse_tx_in_list(tx_in_list, index, count, data) do
    {:ok, tx_in, data} = TxIn.parse(data)
    parse_tx_in_list(tx_in_list ++ [tx_in], index + 1, count, data)
  end

  def is_coinbase?(raw_transaction) do
    first_tx_in = raw_transaction.tx_in |> Enum.at(0)
    first_tx_in |> TxIn.is_coinbase?
  end
end
