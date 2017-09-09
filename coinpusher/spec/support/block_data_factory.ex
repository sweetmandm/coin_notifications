defmodule CoinPusher.BlockDataFactory do
  defmacro __using__(_opts) do
    quote do
      def block_data_factory do
        tx = build(:transaction_data)[:data]
        %{data:
          <<
            2 :: unsigned-little-32,
            0 :: size(256),
            0 :: size(256),
            0 :: unsigned-little-32,
            0 :: unsigned-little-32,
            0 :: unsigned-little-32,
            1 :: unsigned-little-8,
          >> <> tx
        }
      end
    end
  end
end
