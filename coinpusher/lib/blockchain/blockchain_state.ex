defmodule CoinPusher.BlockchainState do
  alias CoinPusher.{LinkedBlock, RawBlock}
  use Agent

  @target_length 16

  defmodule Tip do
    defstruct [:tip, :local_length]
  end

  @type find_block_result :: {:found, pid, integer, %MapSet{}}
                           | {:not_found, nil, integer, %MapSet{}}

  @spec start_link((integer -> list(%RawBlock{}))) :: {:ok, pid}
  def start_link(fetch_func) do
    result = Agent.start_link(fn -> [] end, name: __MODULE__)
    fetch_func.(1) |> Enum.each(&add_block/1)
    result
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  @spec target_length :: integer
  def target_length, do: @target_length

  @spec get_chain_tips :: list(pid)
  def get_chain_tips do
    Agent.get(__MODULE__, fn(state) -> state end)
  end

  @spec add_block(%RawBlock{}) :: {:ok, pid}
  def add_block(block = %RawBlock{}) do
    case find_block_with_id(block.id) do
      {:found, pid, _, _} ->
        {:ok, pid}
      {:not_found, _, _, _} ->
        prev_hash = block |> RawBlock.prev_block_id
        case find_block_with_id(prev_hash) do
          {:not_found, _, _, _} -> add_new_tip(block)
          {:found, previous, _, _} -> extend_chain(block, previous)
        end
    end
  end

  @spec add_new_tip(%RawBlock{}) :: {:ok, pid}
  defp add_new_tip(block) do
    {:ok, linked_block} = LinkedBlock.start(nil, block)
    Agent.update(__MODULE__, fn(tips) ->
      tip = %Tip{tip: linked_block, local_length: 1}
      [tip | tips] |> sort_by_local_length()
    end)
    {:ok, linked_block}
  end

  @spec extend_chain(%RawBlock{}, pid) :: {:ok, pid}
  defp extend_chain(block, previous) when is_pid(previous) do
    {:ok, linked_block} = LinkedBlock.start(previous, block)
    trim_chain_from(linked_block)
    Agent.update(__MODULE__, fn(tips) ->
      index = Enum.find_index(tips, fn(tip) -> tip.tip == previous end)
      tips = if index, do: List.delete_at(tips, index), else: tips
      tip = %Tip{tip: linked_block, local_length: chain_length(linked_block)}
      [tip | tips] |> sort_by_local_length()
    end)
    {:ok, linked_block}
  end

  @spec extend_backward(pid, pid, %RawBlock{}) :: {:ok, pid}
  def extend_backward(tip, last, new_last) when is_pid(last) do
    {:ok, previous} = LinkedBlock.start(nil, new_last)
    last |> LinkedBlock.set_previous(previous)
    trim_chain_from(tip)
    Agent.update(__MODULE__, fn(tips) ->
      needs_recount = Enum.find_index(tips, fn(chain_tip) -> chain_tip.tip == tip end)
      tips = tips |> List.replace_at(
        needs_recount,
        %Tip{tip: tip, local_length: chain_length(tip)}
      )
      merged_index = Enum.find_index(tips, fn(chain_tip) ->
        # This will return non-nil if we merge into an existing tip
        # while extending a chain backwards.
        tip_block = chain_tip.tip |> LinkedBlock.block
        tip_block.id == new_last.id
      end)
      tips = if merged_index, do: List.delete_at(tips, merged_index), else: tips
      tips |> sort_by_local_length()
    end)
    {:ok, previous}
  end

  @spec sort_by_local_length(list(%Tip{})) :: list(%Tip{})
  defp sort_by_local_length(tips) do
    tips
    |> Enum.sort(&( &1.local_length > &2.local_length ))
  end

  @spec chain_length(pid) :: integer
  def chain_length(tip, count \\ 0)

  def chain_length(nil, count) do
    count
  end

  def chain_length(tip, count) do
    chain_length(tip |> LinkedBlock.previous, count + 1)
  end

  @spec trim_chain_from(pid) :: :ok
  defp trim_chain_from(tip) do
    cond do
      chain_length(tip) <= @target_length ->
        :ok
      true ->
        {:found, block, _depth, _visited} = find_block(tip, 1, MapSet.new(), fn(block) ->
          new_last = block |> LinkedBlock.previous
          new_last != nil and new_last |> LinkedBlock.previous == nil
        end)
        if block do
          last = block |> LinkedBlock.previous
          Process.exit(last, :kill)
          block |> LinkedBlock.set_previous(nil)
        end
    end
  end

  @spec each_block(pid, integer, (pid, integer -> any)) :: :ok
  def each_block(block, depth \\ 1, func)

  def each_block(block, depth, func) when is_pid(block) do
    func.(block, depth)
    previous = LinkedBlock.previous(block)
    each_block(previous, depth + 1, func)
  end

  def each_block(nil, _depth, _func) do
    :ok
  end

  @spec find_block_with_id(String.t) :: find_block_result
  def find_block_with_id(hash) do
    find_block(fn(candidate) ->
      hash == LinkedBlock.block(candidate).id
    end)
  end

  @spec find_block((pid -> boolean)) :: {pid | nil, integer, %MapSet{}}
  def find_block(func) do
    tips = get_chain_tips()
    result = tips |> Enum.reduce_while({:not_found, nil, 0, MapSet.new()}, fn(tip, acc) ->
      {_, _, _, visited} = acc
      find_result = find_block(tip.tip, 1, visited, func)
      case find_result do
        {:not_found, _, _, _} -> {:cont, find_result}
        {:found, _, _, _} -> {:halt, find_result}
      end
    end)
    result
  end

  @spec find_block(pid, integer, %MapSet{}, (pid -> boolean)) :: find_block_result
  defp find_block(block, depth, visited, func) when is_pid(block) do
    block_id = if Process.alive?(block), do: LinkedBlock.block(block).id, else: nil

    cond do
      block_id == nil or MapSet.member?(visited, block_id) ->
        {:not_found, nil, 0, visited}
      func.(block) ->
        {:found, block, depth, visited}
      true ->
        visited = MapSet.put(visited, block_id)
        previous = LinkedBlock.previous(block)
        find_block(previous, depth + 1, visited, func)
    end
  end

  defp find_block(nil, _depth, visited, _func) do
    {:not_found, nil, 0, visited}
  end
end
