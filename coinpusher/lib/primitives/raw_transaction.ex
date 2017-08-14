# https://en.bitcoin.it/wiki/Protocol_documentation#tx
defmodule CoinPusher.RawTransaction do
  alias CoinPusher.{VarInt, TxIn, TxOut}

  defstruct [:version, :tx_in, :tx_out, :lock_time]

  def parse(data) do
    <<version :: signed-integer-little-32, rest :: binary >> = data
    tx = parse(version, rest)
    {:ok, tx}
  end

  defp parse(version = 2, data) do
    {:ok, tx_in_count, data} = VarInt.parse(data)
    {:ok, tx_in_list, data} = parse_list(tx_in_count, data, &TxIn.parse/1)
    {:ok, tx_out_count, data} = VarInt.parse(data)
    {:ok, tx_out_list, data} = parse_list(tx_out_count, data, &TxOut.parse/1)
    <<lock_time :: unsigned-integer-32>> = data
    %CoinPusher.RawTransaction{
      version: version,
      tx_in: tx_in_list,
      tx_out: tx_out_list,
      lock_time: lock_time
    }
  end

  defp parse_list(list \\ [], index \\ 0, count, data, func)

  defp parse_list(list, max, max, data, _func) do
    {:ok, list, data}
  end

  defp parse_list(list, index, count, data, func) do
    {:ok, item, data} = func.(data)
    parse_list(list ++ [item], index + 1, count, data, func)
  end

  def is_coinbase?(raw_transaction) do
    first_tx_in = raw_transaction.tx_in |> Enum.at(0)
    first_tx_in |> TxIn.is_coinbase?
  end
end
