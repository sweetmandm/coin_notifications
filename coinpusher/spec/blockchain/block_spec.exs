defmodule BlockSpec do
  use ESpec
  import CoinPusher.Factory

  let :block, do: build(:block)

  describe "the block" do
    it "gets the block" do
      expect block().prev_block |> to(eq <<0 :: size(256)>>)
    end
  end
end
