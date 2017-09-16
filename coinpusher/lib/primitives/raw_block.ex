defmodule CoinPusher.RawBlock do
  alias CoinPusher.{VarInt, DoubleSha256, RawTransaction, TransactionInfo, AddressListeners}
  import CoinPusher.ParseList
  import CoinPusher.ReverseBytes

  defstruct [:id, :version, :prev_block, :merkle_root, :timestamp, :bits, :nonce, :transaction_infos]

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
    {:ok, infos, <<>>} = parse_list(txn_count, rest, &__MODULE__.parse_transaction_info/1)

    infos = infos
            |> Enum.filter(fn(info) ->
              info |> AddressListeners.any_listeners?
            end)

    block = %CoinPusher.RawBlock{
      id: DoubleSha256.to_string(header),
      version: version,
      prev_block: prev_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce,
      transaction_infos: infos
    }

    {:ok, block}
  end

  @spec parse_transaction_info(binary) :: {:ok, %TransactionInfo{}, binary}
  def parse_transaction_info(data) do
    {:ok, tx, rest} = RawTransaction.parse(data)
    {:ok, TransactionInfo.from(tx), rest}
  end

  @spec contains_transaction(%__MODULE__{}, String.t) :: boolean
  def contains_transaction(block, tx_id) do
    ids = block.transaction_infos |> Enum.map(&(&1.id))
    Enum.member?(ids, tx_id)
  end

  @spec prev_block_id(%__MODULE__{}) :: String.t
  def prev_block_id(block) do
    block.prev_block |> reverse_bytes |> Base.encode16(case: :lower)
  end
end
