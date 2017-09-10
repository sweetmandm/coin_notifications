defmodule CoinPusher.BlockchainStateSpec do
  use ESpec, async: false
  import CoinPusher.Factory
  alias CoinPusher.LinkedBlock

  def tips, do: CoinPusher.BlockchainState.get_chain_tips()
    def fetch_func do
      (fn(count) -> (build(:blockchain) |> with_count(count))[:blocks] end)
    end

  describe "the chain tips" do
    let :previous do
      tip = (tips() |> Enum.at(0)).tip
      tip |> LinkedBlock.previous |> LinkedBlock.block
    end
    let :new_block do
      build(:block) |> with_prev(previous())
    end

    before do
      CoinPusher.BlockchainState.start_link(fetch_func())
    end

    finally do
      CoinPusher.BlockchainState.stop()
    end

    it "Holds a single tip when there is no fork" do
      expect(tips() |> Enum.count) |> to(eq 1)
    end

    it "Adds a new tip when ther is a fork" do
      {:ok, _block} = CoinPusher.BlockchainState.add_block(new_block())
      expect(tips() |> Enum.count) |> to(eq 2)
    end
  end
end
