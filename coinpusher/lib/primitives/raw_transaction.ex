# https://en.bitcoin.it/wiki/Protocol_documentation#tx
require IEx
defmodule CoinPusher.RawTransaction do
  alias CoinPusher.{VarInt, TxIn, OutPoint}

  defstruct [:version, :tx_in_count, :tx_in]

  def parse(data) do
    <<version :: signed-integer-little-32, rest :: binary >> = data
    tx = parse(version, rest)
    {:ok, tx}
  end

  defp parse(version = 2, data) do
    {:ok, tx_in_count, data} = VarInt.parse(data)
    {:ok, tx_in, data} = parse_tx_in([], 0, tx_in_count, data)
    IEx.pry
    %CoinPusher.RawTransaction{
      version: version,
      tx_in_count: tx_in_count,
      tx_in: tx_in
    }
  end

  defp parse_tx_in(tx_in, max, max, data) do
    {:ok, tx_in, data}
  end

  defp parse_tx_in(tx_in, index, count, data) do
    {:ok, tx, data} = TxIn.parse(data)
    parse_tx_in(tx_in ++ [tx], index + 1, count, data)
  end

  def is_coinbase?(raw_transaction) do
    first_tx_in = raw_transaction.tx_in |> Enum.at(0)
    OutPoint.is_coinbase?(first_tx_in)
  end
end
