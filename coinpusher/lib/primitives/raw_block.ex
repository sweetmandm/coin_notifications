defmodule CoinPusher.RawBlock do
  alias CoinPusher.{VarInt, DoubleSha256, RawTransaction}
  import CoinPusher.ParseList
  import CoinPusher.ReverseBytes

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
      id: DoubleSha256.to_string(header),
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

  @spec transaction_ids(%__MODULE__{}) :: list(String.t)
  def transaction_ids(block) do
    block.txns |> Enum.map(&(&1.id))
  end

  @spec contains_transaction(%__MODULE__{}, String.t) :: boolean
  def contains_transaction(block, tx_id) do
    ids = __MODULE__.transaction_ids(block)
    Enum.member?(ids, tx_id)
  end

  @spec prev_block_id(%__MODULE__{}) :: String.t
  def prev_block_id(block) do
    block.prev_block |> reverse_bytes |> Base.encode16(case: :lower)
  end
end
