# https://en.bitcoin.it/wiki/Protocol_documentation#tx
defmodule CoinPusher.TxIn do
  alias CoinPusher.{OutPoint, VarInt}

  defstruct [:previous_output, :signature_script, :sequence, :witnesses]

  def parse(data) do
    {:ok, out_point, data} = OutPoint.parse(data)
    {:ok, script_length, data} = VarInt.parse(data)
    <<sig :: binary-size(script_length), data :: binary>> = data
    <<sequence :: unsigned-integer-32, data :: binary>> = data
    tx_in = %CoinPusher.TxIn{
      previous_output: out_point,
      signature_script: sig,
      sequence: sequence,
      witnesses: nil
    }
    {:ok, tx_in, data}
  end

  def is_coinbase?(tx_in) do
    tx_in.previous_output |> OutPoint.is_coinbase?
  end
end
