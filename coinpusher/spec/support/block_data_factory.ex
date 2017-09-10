defmodule CoinPusher.BlockDataFactory do
  defmacro __using__(_opts) do
    quote do
      import CoinPusher.ReverseBytes

      def block_data_factory do
        tx_count = 1
        tx = build(:transaction_data)[:data]
        tx_id = tx |> CoinPusher.TxId.from_raw
        merkle = tx_id |> CoinPusher.DoubleSha256.double_sha256
        test_sequence = sequence("") |> Integer.parse |> elem(0)

        %{data:
          <<2 :: unsigned-little-32,
            0 :: size(256)>>
          <> merkle
          <> <<test_sequence :: unsigned-little-32,
               0 :: unsigned-little-32,
               0 :: unsigned-little-32,
               tx_count>>
          <> tx
        }
      end
    end
  end
end
