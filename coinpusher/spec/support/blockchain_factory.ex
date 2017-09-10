defmodule CoinPusher.BlockchainFactory do
  defmacro __using__(_opts) do
    quote do
      def blockchain_factory do
        %{blocks: []}
      end

      def with_count(chain, count) do
        %{chain | blocks: (chain[:blocks] || []) ++ make_chain(count)}
      end

      defp make_chain(count, prev \\ nil, chain \\ [])

      defp make_chain(0, _prev, chain) do
        chain
      end

      defp make_chain(count, prev_block, chain) do
        new_block = build(:block) |> with_prev(prev_block)
        make_chain(count - 1, new_block, chain ++ [new_block])
      end
    end
  end
end
