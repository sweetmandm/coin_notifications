defmodule CoinPusher.TransactionDataFactory do
  defmacro __using__(_opts) do
    quote do
      def transaction_data_factory do
        %{data:
          Base.decode16(
            "0200000001CB326BCC8B0D43B4334DD9FD298E121B04E4A133FA47F2070D8B17AD763" <>
            "592D3010000006A4730440220432F16DA7CEE169C4158193396470FE8B633770B7DB8" <>
            "AAF276122867A83DF86C02203C85A98DAE2EC3F449BC648A28FCC0F5D9101BE6C06B9" <>
            "873169E5A0AE144D0F4012102FDE2CE1A9EA209CF39E1749866DAA041E7E7B77134F2" <>
            "D335C856DDF2C8B96F0BFEFFFFFF0200E1F505000000001976A914CC33BBDEC70A5A8" <>
            "1D420E9E244261695B9B001B488AC30BEFA02000000001976A91498DF0D25F4AC4C7D" <>
            "C3CC225E749584F45F8B190B88ACC8020000"
          ) |> elem(1)
        }
      end
    end
  end
end
