defmodule RawBlockSpec do
  use ESpec

  let :result, do: CoinPusher.RawBlock.parse(data())
  subject do: result() |> elem(1)

  describe "the raw block parse" do
    let :data do
      Base.decode16(
        "00000020172E59E8ACC8C9212F92705087931BA55AF79DE14FFD60A679E047FFAE4" <>
        "9C15C9CFA373A6AF86C09EBA4982FF68C87658E09154E8C7851F3A2C2D1405A1440" <>
        "97DB33AB59FFFF7F200000000001020000000001010000000000000000000000000" <>
        "000000000000000000000000000000000000000FFFFFFFF0502E4020101FFFFFFFF" <>
        "02205FA01200000000232103EBBDEB4724867B180834CBFFBE6726CCF96269BC6E0" <>
        "3A4810A0D48EA4CFDB78FAC0000000000000000266A24AA21A9EDE2F61C3F71D1DE" <>
        "FD3FA999DFA36953755C690689799962B48BEBD836974E8CF901200000000000000" <>
        "00000000000000000000000000000000000000000000000000000000000"
      ) |> elem(1)
    end

    it "parses the id" do
      expect subject().id |> to(
        eq "1154b08c450c8f0b7f8a0f0732134816dd0a1ab270a3800bbaa011b42a2dc600"
      )
    end

    it "parses the version" do
      expect subject().version |> to(eq 536870912)
    end

    it "parses the timestamp" do
      expect subject().timestamp |> to(eq 1504392155)
    end

    it "parses the nonce" do
      expect subject().nonce |> to(eq 0)
    end

    it "parses the txn_count" do
      expect subject().txn_count |> to(eq 1)
    end

    describe "the previous block hash" do
      let :prev_block do
        <<23, 46, 89, 232, 172, 200, 201, 33, 47, 146, 112, 80, 135, 147, 27, 165,
          90, 247, 157, 225, 79, 253, 96, 166, 121, 224, 71, 255, 174, 73, 193, 92>>
      end

      it "parses the previous block hash" do
        expect subject().prev_block |> to(eq prev_block())
      end
    end

    describe "the merkle root" do
      let :merkle_root do
        <<156, 250, 55, 58, 106, 248, 108, 9, 235, 164, 152, 47, 246, 140, 135, 101,
          142, 9, 21, 78, 140, 120, 81, 243, 162, 194, 209, 64, 90, 20, 64, 151>>
      end

      it "parses the merkle root" do
        expect subject().merkle_root |> to(eq merkle_root())
      end
    end

    describe "the transactions" do
      let :txns do
        [%CoinPusher.RawTransaction{
          version: 2,
          lock_time: 0,
          tx_in: [
            %CoinPusher.TxIn{
              sequence: 4294967295,
              signature_script: <<2, 228, 2, 1, 1>>,
              previous_output: %CoinPusher.OutPoint{
                hash: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
                index: 4294967295
              },
              witnesses: [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
            }
          ],
          tx_out: [
            %CoinPusher.TxOut{pk_script: <<33, 3, 235, 189, 235, 71, 36, 134, 123,
              24, 8, 52, 203, 255, 190, 103, 38, 204, 249, 98, 105, 188, 110, 3,
              164, 129, 10, 13, 72, 234, 76, 253, 183, 143, 172>>,
              value: 312500000},
            %CoinPusher.TxOut{pk_script: <<106, 36, 170, 33, 169, 237, 226, 246,
              28, 63, 113, 209, 222, 253, 63, 169, 153, 223, 163, 105, 83, 117, 92,
              105, 6, 137, 121, 153, 98, 180, 139, 235, 216, 54, 151, 78, 140, 249>>,
              value: 0}
          ]
        }]
      end

      it "parses the transactions" do
        expect subject().txns |> to(eq txns())
      end
    end
  end
end
