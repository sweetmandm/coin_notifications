defmodule CoinPusher.BlockchainState do
  alias CoinPusher.{LinkedBlock, RawBlock}
  use Agent

  @spec start_link :: {:ok, pid}
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @spec get_chain_tips :: list(pid)
  def get_chain_tips do
    Agent.get(__MODULE__, fn(state) -> state end)
  end

  @spec add_block(%RawBlock{}) :: :ok
  def add_block(block = %RawBlock{}) do
    prev_hash = block |> RawBlock.prev_block_id
    case find_block_with_id(prev_hash) do
      {:ok, nil, _depth} ->
        {:ok, linked_block} = LinkedBlock.start_link(nil, block)
        Agent.update(__MODULE__, fn(tips) ->
          [linked_block | tips]
        end)
      {:ok, previous, _depth} ->
        {:ok, linked_block} = LinkedBlock.start_link(previous, block)
        Agent.update(__MODULE__, fn(tips) ->
          tips = List.delete(tips, previous)
          [linked_block | tips]
        end)
    end
  end

  @spec find_block_with_id(String.t) :: {:ok, pid | nil, integer}
  def find_block_with_id(hash) do
    result = find_block(fn(candidate) ->
      hash == LinkedBlock.block(candidate).id
    end)
    {:ok, result |> elem(0), result |> elem(1)}
  end

  @spec find_block((pid -> boolean)) :: {pid | nil, integer, %MapSet{}}
  def find_block(func) do
    tips = get_chain_tips()
    result = tips |> Enum.reduce_while({nil, 0, MapSet.new()}, fn(tip, acc) ->
      visited = acc |> elem(2)
      find_result = find_block(tip, 0, visited, func)
      case find_result do
        {nil, _depth, _visited} -> {:cont, find_result}
        {pid, _depth, _visited} when is_pid(pid) -> {:halt, find_result}
      end
    end)
    result
  end

  @spec find_block(pid, integer, %MapSet{}, (pid -> boolean)) :: {pid | nil, integer, %MapSet{}}
  defp find_block(block, depth, visited \\ MapSet.new(), func)

  defp find_block(nil, depth, visited, _func) do
    {nil, depth, visited}
  end

  defp find_block(block, depth, visited, func) when is_pid(block) do
    id = LinkedBlock.block(block).id
    cond do
      func.(block) ->
        {block, depth, visited}
      MapSet.member?(visited, id) ->
        {nil, depth, visited}
      true ->
        visited = MapSet.put(visited, id)
        previous = LinkedBlock.previous(block)
        find_block(previous, depth + 1, visited, func)
    end
  end
end
