defmodule CoinPusher.BlockchainSpec do
  use ESpec, async: false
  import CoinPusher.Factory
  alias CoinPusher.{LinkedBlock, Blockchain, BlockchainState}

  def block(prev, tx) do
    build(:block) |> with_prev(prev) |> with_transactions(tx)
  end

  let :fetch_func do
    (fn(_count) -> (build(:blockchain) |> with_count(30))[:blocks] end)
  end

  before do
    BlockchainState.start_link(fetch_func())
  end

  finally do
    BlockchainState.stop()
  end

  describe "finding a transaction" do
    let :tx, do: build(:transaction) |> with_id("12341234")
    let :prev_block do
      (BlockchainState.get_chain_tips()
      |> Enum.at(0)).tip
      |> LinkedBlock.previous
      |> LinkedBlock.previous
      |> LinkedBlock.previous
      |> LinkedBlock.block
      |> with_id("aabbccdd")
    end
    let :block do
      build(:block) |> with_prev(prev_block()) |>  with_transactions([tx()])
    end
    subject do
      Blockchain.block_for_transaction(tx().id)
    end
    let :result, do: subject() |> elem(0)
    let :found_block, do: subject() |> elem(1) |> LinkedBlock.block
    let :depth, do: subject() |> elem(2)

    before do
      BlockchainState.add_block(block())
    end

    it "locates the transaction" do
      expect result() |> to(eq :found)
    end

    it "returns the block" do
      expect found_block().id |> to(eq block().id)
    end

    describe "confirmation counting" do
      context "one confirmation" do
        it do: expect depth() |> to(eq 1)
      end

      context "three confirmations" do
        before do
          block_1 = build(:block) |> with_prev(block())
          block_2 = build(:block) |> with_prev(block_1)
          BlockchainState.add_block(block_1)
          BlockchainState.add_block(block_2)
        end

        it do: expect depth() |> to(eq 3)
      end
    end
  end
end
