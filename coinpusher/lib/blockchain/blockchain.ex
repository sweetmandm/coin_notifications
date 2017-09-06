defmodule CoinPusher.Blockchain do
  alias CoinPusher.{RawBlock, RPC, LinkedBlock, BlockchainState}

  @spec handle_receive_block(%RawBlock{}) :: any
  def handle_receive_block(block) do
    BlockchainState.add_block(block)
  end

  @spec best_block_hash :: String.t
  def best_block_hash do
  end

  @spec fetch_best_block :: %RawBlock{}
  def fetch_best_block do
    {:ok, %{"result" => block_hash}} = RPC.get_best_block_hash()
    {:ok, %{"result" => hex}} = RPC.get_raw_block(block_hash)
    {:ok, data} = hex |> Base.decode16(case: :lower)
    {:ok, block} = RawBlock.parse(data)
    block
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
