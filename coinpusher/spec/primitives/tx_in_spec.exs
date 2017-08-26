defmodule TxInSpec do
  use ESpec

  let :result, do: CoinPusher.TxIn.parse(data())
  let :rest, do: result() |> elem(2)
  subject do: result() |> elem(1)

  describe "the tx_in" do
    let :data do
      <<
        1 :: size(256),
        0x88, 0x77, 0x66, 0x55,
        4,
        0x01, 0x02, 0x03, 0x04,
        0xFF, 0x00, 0x00, 0x00,
        "the rest"
      >>
    end

    it "parses the out_point" do
      expect subject().previous_output.hash |> to(eq <<1 :: size(256)>>)
      expect subject().previous_output.index |> to(eq 0x55667788)
    end

    it "parses the signature script" do
      expect subject().signature_script |> to(eq <<1, 2, 3, 4>>)
    end

    it "parses the sequence" do
      expect subject().sequence |> to(eq 0xFF000000)
    end

    it "returns the remainder" do
      expect rest() |> to(eq "the rest")
    end
  end
end
