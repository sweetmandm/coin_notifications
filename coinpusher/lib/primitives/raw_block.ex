defmodule CoinPusher.RawBlock do
  alias CoinPusher.{VarInt, BlockHash, RawTransaction}
  import CoinPusher.ParseList

  defstruct [:id, :version, :prev_block, :merkle_root, :timestamp, :bits, :nonce, :txn_count, :txns]

  @spec parse(binary) :: {:ok, %CoinPusher.RawBlock{}}
  def parse(data) do
    <<header :: binary-80, _rest :: binary>> = data

    <<version :: signed-little-32,
      prev_block :: binary-32,
      merkle_root :: binary-32,
      timestamp :: unsigned-little-32,
      bits :: unsigned-little-32,
      nonce :: unsigned-little-32,
      rest :: binary>> = data

    {:ok, txn_count, rest} = VarInt.parse(rest)
    {:ok, txns, <<>>} = parse_list(txn_count, rest, &RawTransaction.parse/1)

    block = %CoinPusher.RawBlock{
      id: BlockHash.to_string(header),
      version: version,
      prev_block: prev_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce,
      txn_count: txn_count,
      txns: txns
    }

    {:ok, block}
  end
end
