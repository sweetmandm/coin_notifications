defmodule CoinPusher.TxOut do
  alias CoinPusher.VarInt

  defstruct [:value, :pk_script]

  def parse(data) do
    <<value :: integer-little-64, data :: binary>> = data
    {:ok, pk_script_length, data} = VarInt.parse(data)
    <<pk_script :: binary-size(pk_script_length), data :: binary>> = data
    tx_out = %CoinPusher.TxOut{
      value: value,
      pk_script: pk_script
    }
    {:ok, tx_out, data}
  end
end
