defmodule RawTransactionSpec do
  require IEx
  use ESpec

  let :result, do: CoinPusher.RawTransaction.parse(data())
  subject do: result() |> elem(1) 

  describe "the raw transaction parse" do
    let :data do
      Base.decode16(
        "0200000001CB326BCC8B0D43B4334DD9FD298E121B04E4A133FA47F2070D8B17AD763" <>
        "592D3010000006A4730440220432F16DA7CEE169C4158193396470FE8B633770B7DB8" <>
        "AAF276122867A83DF86C02203C85A98DAE2EC3F449BC648A28FCC0F5D9101BE6C06B9" <>
        "873169E5A0AE144D0F4012102FDE2CE1A9EA209CF39E1749866DAA041E7E7B77134F2" <>
        "D335C856DDF2C8B96F0BFEFFFFFF0200E1F505000000001976A914CC33BBDEC70A5A8" <>
        "1D420E9E244261695B9B001B488AC30BEFA02000000001976A91498DF0D25F4AC4C7D" <>
        "C3CC225E749584F45F8B190B88ACC8020000"
      ) |> elem(1)
    end

    it "parses the lock time" do
      expect subject().lock_time |> to(eq 712)
    end

    describe "the tx_in" do
      let :expected_tx_in do
        %CoinPusher.TxIn{
          previous_output: %CoinPusher.OutPoint{
            index: 1,
            hash: ("CB326BCC8B0D43B4334DD9FD298E121B04E4A133FA47F2070D8B17AD763592D3"
              |> Base.decode16 |> elem(1))
          },
          sequence: 0xFFFFFFFE,
          signature_script: ("4730440220432F16DA7CEE169C4158193396470FE8B633770B7" <>
            "DB8AAF276122867A83DF86C02203C85A98DAE2EC3F449BC648A28FCC0F5D9101BE6C" <>
            "06B9873169E5A0AE144D0F4012102FDE2CE1A9EA209CF39E1749866DAA041E7E7B77" <>
            "134F2D335C856DDF2C8B96F0B" |> Base.decode16 |> elem(1))
        }
      end

      it "parses the tx_in" do
        expect subject().tx_in |> to(have_count 1)
        expect subject().tx_in |> to(match_list [expected_tx_in()])
      end
    end
  end
end
