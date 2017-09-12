defmodule CoinPusher.Blockchain do
  alias CoinPusher.{RawBlock, RPC, LinkedBlock, BlockchainState}

  @spec handle_receive_block(%RawBlock{}) :: {:ok, pid}
  def handle_receive_block(block) do
    {:ok, linked_block} = BlockchainState.add_block(block)
    case linked_block |> LinkedBlock.previous do
      nil ->
        extend_backward(linked_block, linked_block)
        {:ok, linked_block}
      _ ->
        {:ok, linked_block}
    end
  end

  @spec extend_backward(pid, pid) :: :ok
  defp extend_backward(tip, tail) do
    block = tail |> LinkedBlock.block
    id = block |> RawBlock.prev_block_id
    {:ok, previous_block} = RPC.get_raw_block(id)
    {:ok, previous} = BlockchainState.extend_backward(tip, tail, previous_block)
    previous_id = previous_block |> RawBlock.prev_block_id
    {result, found_join, _, _}  = BlockchainState.find_block_with_id(previous_id)
    cond do
      BlockchainState.chain_length(tip) >= BlockchainState.target_length() -> :ok
      result == :found -> previous |> LinkedBlock.set_previous(found_join)
      result == :not_found -> extend_backward(tip, previous)
    end
  end

  @spec each_block(pid, (pid, integer -> boolean)) :: :ok
  def each_block(tip, func) do
    BlockchainState.each_block(tip, func)
  end

  @spec fetch_initial_blocks(integer) :: list(%RawBlock{})
  def fetch_initial_blocks(count) do
    {:ok, %{"result" => block_hash}} = RPC.get_best_block_hash()
    fetch_blocks(count, block_hash)
  end

  @spec fetch_blocks(integer, String.t, list(%RawBlock{})) :: list(%RawBlock{})
  def fetch_blocks(count, tip_id, result \\ []) do
    case Enum.count(result) do
      ^count ->
        result
      _ ->
        {:ok, block} = RPC.get_raw_block(tip_id)
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
  def confirmations_for_transaction(transaction) when is_binary(transaction) do
    result = block_for_transaction(transaction)
    case result do
      {:not_found, _, _, _} -> 0
      {:found, pid, depth, _} when is_pid(pid) -> depth
    end
  end
end
