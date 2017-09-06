defmodule CoinPusher.BlockchainState do
  alias CoinPusher.{LinkedBlock, RawBlock, Blockchain}
  use Agent

  @target_length 20

  @spec start_link :: {:ok, pid}
  def start_link do
    result = Agent.start_link(fn -> [] end, name: __MODULE__)
    Blockchain.fetch_initial_blocks(@target_length)
    |> Enum.each(&add_block/1)
    result
  end

  @spec get_chain_tips :: list(pid)
  def get_chain_tips do
    Agent.get(__MODULE__, fn(state) -> state end)
  end

  @spec add_block(%RawBlock{}) :: :ok
  def add_block(block = %RawBlock{}) do
    prev_hash = block |> RawBlock.prev_block_id
    case find_block_with_id(prev_hash) do
      {:not_found, _, _, _} -> add_new_tip(block)
      {:found, previous, _, _} -> extend_chain(block, previous)
    end
  end

  @spec add_new_tip(%RawBlock{}) :: :ok
  defp add_new_tip(block) do
    {:ok, linked_block} = LinkedBlock.start_link(nil, block)
    Agent.update(__MODULE__, fn(tips) ->
      [linked_block | tips]
    end)
  end

  @spec extend_chain(%RawBlock{}, pid) :: :ok
  defp extend_chain(block, previous) when is_pid(previous) do
    {:ok, linked_block} = LinkedBlock.start_link(previous, block)
    Agent.update(__MODULE__, fn(tips) ->
      tips = List.delete(tips, previous)
      [linked_block | tips]
    end)
    trim_chain_from(linked_block)
  end

  @spec chain_length(pid) :: integer
  def chain_length(tip, count \\ 0)

  def chain_length(nil, count) do
    count
  end

  def chain_length(tip, count) do
    chain_length(tip |> LinkedBlock.previous, count + 1)
  end

  defp trim_chain_from(tip) do
    cond do
      chain_length(tip) <= @target_length ->
        :ok
      true ->
        {:found, block, _depth, _visited} = find_block(tip, 1, MapSet.new(), fn(block) ->
          block |> LinkedBlock.previous |> LinkedBlock.previous == nil
        end)
        last = block |> LinkedBlock.previous
        Process.exit(last, :kill)
        block |> LinkedBlock.set_previous(nil)
    end
  end

  @spec find_block_with_id(String.t) :: {:found, pid, integer, %MapSet{}} | {:not_found, nil, integer, %MapSet{}}
  def find_block_with_id(hash) do
    find_block(fn(candidate) ->
      hash == LinkedBlock.block(candidate).id
    end)
  end

  @spec find_block((pid -> boolean)) :: {pid | nil, integer, %MapSet{}}
  def find_block(func) do
    tips = get_chain_tips()
    result = tips |> Enum.reduce_while({:not_found, nil, 0, MapSet.new()}, fn(tip, acc) ->
      visited = acc |> elem(2)
      find_result = find_block(tip, 1, visited, func)
      case find_result do
        {:not_found, _, _, _} -> {:cont, find_result}
        {:found, _, _, _} -> {:halt, find_result}
      end
    end)
    result
  end

  @spec find_block(pid, integer, %MapSet{}, (pid -> boolean)) :: {pid | nil, integer, %MapSet{}}
  defp find_block(block, depth, visited, func) when is_pid(block) do
    id = LinkedBlock.block(block).id
    cond do
      func.(block) ->
        {:found, block, depth, visited}
      MapSet.member?(visited, id) ->
        {:not_found, nil, 0, visited}
      true ->
        visited = MapSet.put(visited, id)
        previous = LinkedBlock.previous(block)
        find_block(previous, depth + 1, visited, func)
    end
  end

  defp find_block(nil, _depth, visited, _func) do
    {:not_found, nil, 0, visited}
  end
end
