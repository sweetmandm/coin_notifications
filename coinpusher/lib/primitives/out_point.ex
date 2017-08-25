defmodule CoinPusher.OutPoint do
  defstruct [:hash, :index]

  def parse(<<hash :: binary-size(32), index :: unsigned-integer-little-32, rest :: binary>>) do
    out_point = %CoinPusher.OutPoint{
      hash: hash,
      index: index
    }
    {:ok, out_point, rest}
  end

  def parse(_other), do: :error

  def is_coinbase?(out_point) do
    out_point.hash == coinbase_hash() && out_point.index == coinbase_index()
  end

  defp coinbase_hash, do: <<0 :: size(256)>>

  defp coinbase_index, do: 0xFFFFFFFF
end
