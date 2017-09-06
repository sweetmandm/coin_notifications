defmodule CoinPusher.Blockchain do
  alias CoinPusher.{RawBlock, RPC, LinkedBlock, BlockchainState}

  @spec handle_receive_block(%RawBlock{}) :: any
  def handle_receive_block(block) do
    BlockchainState.add_block(block)
  end

  @spec fetch_initial_blocks(integer) :: list(%RawBlock{})
  def fetch_initial_blocks(count) do
    {:ok, %{"result" => block_hash}} = RPC.get_best_block_hash()
    fetch_blocks(count, block_hash)
  end

  def fetch_blocks(count, tip_id, result \\ []) do
    cond do
      Enum.count(result) == count ->
        result
      true ->
        {:ok, %{"result" => hex}} = RPC.get_raw_block(tip_id)
        {:ok, data} = hex |> Base.decode16(case: :lower)
        {:ok, block} = RawBlock.parse(data)
        fetch_blocks(count, block |> RawBlock.prev_block_id, [block | result])
    end
  end

  @spec block_for_transaction(String.t) :: {:ok, %RawBlock{}} | {:error, any}
  def block_for_transaction(transaction) do
    BlockchainState.find_block(fn(candidate) ->
      block = LinkedBlock.block(candidate)
      RawBlock.contains_transaction(block, transaction)
    end)
  end

  @spec confirmations_for_transaction(String.t) :: integer
  def confirmations_for_transaction(transaction) do
    result = block_for_transaction(transaction)
    case result do
      {nil, _, _} -> 0
      {pid, depth, _} when is_pid(pid) -> depth
    end
  end
end
