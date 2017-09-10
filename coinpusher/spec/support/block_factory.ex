defmodule CoinPusher.BlockFactory do
  defmacro __using__(_opts) do
    quote do
      import CoinPusher.ReverseBytes

      def block_factory do
        CoinPusher.RawBlock.parse(build(:block_data)[:data]) |> elem(1)
      end

      def with_prev(block, prev_block) do
        if prev_block do
          id = prev_block.id
               |> Base.decode16(case: :lower)
               |> elem(1)
               |> reverse_bytes
          %{block | prev_block: id}
        else
          block
        end
      end

      def with_id(block, mocked_id) do
        %{block | id: mocked_id}
      end

      def with_transactions(block, tx) do
        if tx do
          # Note the merkle root will be wrong after this,
          # unless this is changed to update it.
          %{block |
            txn_count: tx |> Enum.count,
            txns: tx
          }
        else
          block
        end
      end
    end
  end
end
