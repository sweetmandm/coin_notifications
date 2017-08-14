defmodule VarIntSpec do
  use ESpec

  subject do: CoinPusher.VarInt.parse(data())

  describe "uint8" do
    let :data, do: <<1>>
    it do: should eq({:ok, 1, <<>>})
  end

  describe "uint16" do
    let :data, do: <<0xFD, 0x00, 0xFF>>
    it do: should eq({:ok, 65280, <<>>})
  end

  describe "uint32" do
    let :data, do: <<0xFE, 0x00, 0x00, 0x00, 0xFF>>
    it do: should eq({:ok, 4278190080, <<>>})
  end

  describe "uint64" do
    let :data, do: <<0xFF, 0x00 ,0x00, 0x00 ,0x00, 0x00, 0x00, 0x00, 0xFF>>
    it do: should eq({:ok, 18374686479671623680, <<>>})
  end

  describe "extra data" do
    let :data, do: <<0xFD, 0x00, 0xFF, "Hello">>
    it do: should eq({:ok, 65280, <<"Hello">>})
  end
end
