defmodule OutPointSpec do
  use ESpec

  let :result, do: CoinPusher.OutPoint.parse(data())
  let :rest, do: result() |> elem(2)
  subject do: result() |> elem(1)

  context "the coinbase outpoint" do
    let :data, do: <<0 :: size(256), 0xFF, 0xFF, 0xFF, 0xFF, "the rest">>

    it "parses the hash" do
      expect subject().hash |> to(eq <<0 :: size(256)>>)
    end

    it "parses the index" do
      expect subject().index |> to(eq 0xFFFFFFFF)
    end

    it "identifies as a coinbase" do
      expect (subject() |> CoinPusher.OutPoint.is_coinbase?) |> to(be_true())
    end

    it "returns the remaining data" do
      expect rest() |>  to(eq <<"the rest">>)
    end
  end

  context "invalid inputs" do
    let :data, do: <<0 :: size(200)>>

    it "indicates an error" do
      expect result() |> to(eq :error)
    end
  end
end
