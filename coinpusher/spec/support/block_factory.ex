defmodule CoinPusher.BlockFactory do
  defmacro __using__(_opts) do
    quote do
      def block_factory do
        CoinPusher.RawBlock.parse(build(:block_data)[:data]) |> elem(1)
      end
    end
  end
end
