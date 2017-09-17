defmodule CoinPusher.BlockchainStateSpec do
  use ESpec, async: false
  import CoinPusher.Factory
  alias CoinPusher.LinkedBlock

  def tips, do: CoinPusher.BlockchainState.get_chain_tips()
  def new_block(prev), do: build(:block) |> with_prev(prev)

  let :fetch_func do
    (fn(_count) -> (build(:blockchain) |> with_count(30))[:blocks] end)
  end
  before do
    CoinPusher.BlockchainState.start_link(fetch_func())
  end

  finally do
    CoinPusher.BlockchainState.stop()
  end

  describe "the chain tips" do
    let :previous do
      tip = (tips() |> Enum.at(0)).tip
      tip |> LinkedBlock.previous |> LinkedBlock.block
    end

    it "Holds a single tip when there is no fork" do
      expect (tips() |> Enum.count) |> to(eq 1)
    end

    it "Adds a new tip when there is a fork" do
      {:ok, _block} = CoinPusher.BlockchainState.add_block(new_block(previous()))
      expect (tips() |> Enum.count) |> to(eq 2)
    end

    it "Sorts the longest chain first" do
      block_1 = new_block(nil)
      block_2 = new_block(block_1)
      block_3 = new_block(block_2)
      block_4 = new_block(block_1)

      [block_1, block_2, block_3, block_4]
      |> Enum.map(&CoinPusher.BlockchainState.add_block/1)

      expect tips() |> Enum.count |> to(eq 3)
      expect (tips() |> Enum.at(0)).local_length |> to(eq 30)
      expect (tips() |> Enum.at(1)).local_length |> to(eq 3)
      expect (tips() |> Enum.at(2)).local_length |> to(eq 2)
    end
  end

  describe "finding a block" do
    let :to_find do
      tip = (tips() |> Enum.at(0)).tip
      tip 
      |> LinkedBlock.previous
      |> LinkedBlock.previous
      |> LinkedBlock.block
    end

    let :find do
      CoinPusher.BlockchainState.find_block(fn(candidate) ->
        LinkedBlock.block(candidate).id == to_find().id
      end)
    end
    let :result, do: find() |> elem(0)
    let :pid, do: find() |> elem(1)
    let :found_block, do: pid() |> LinkedBlock.block
    let :depth, do: find() |> elem(2)

    it "finds an existing block" do
      expect found_block().id |> to(eq to_find().id)
    end

    it "returns the block depth" do
      expect depth() |> to(eq 3)
    end

    context "when the block does not exist" do
      let :to_find, do: new_block(nil)

      it "reports not found" do
        expect result() |> to(eq :not_found)
        expect pid() |> to(be_nil())
      end
    end
  end

  describe "iterating blocks" do
    let :call_count, do: Agent.start_link((fn -> 0 end)) |> elem(1)

    it "executes the given function on each block" do
      tip = (tips() |> Enum.at(0)).tip
      CoinPusher.BlockchainState.each_block(tip, fn(_block, _depth) ->
        Agent.update(call_count(), fn(count) -> count + 1 end)
      end)
      expect Agent.get(call_count(), fn(count) -> count end) |> to(eq 30)
    end
  end
end
