defmodule CoinPusher.TransactionFactory do
  defmacro __using__(_opts) do
    quote do
      def transaction_factory do
        CoinPusher.RawTransaction.parse(build(:transaction_data)[:data]) |> elem(1)
      end

      def with_id(tx, id) do
        %{tx | id: id}
      end
    end
  end
end
