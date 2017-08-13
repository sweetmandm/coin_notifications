# https://en.bitcoin.it/wiki/Protocol_documentation#tx
require IEx
defmodule CoinPusher.TxIn do
  defstruct [:previous_output, :script_length, :signature_script, :sequence]
  alias CoinPusher.OutPoint

  def parse(data) do
    {:ok, out_point, rest} = OutPoint.parse(data)
    tx = %CoinPusher.TxIn{
      previous_output: out_point,
      script_length: 'todo',
      signature_script: 'todo',
      sequence: 'todo'
    }
    {:ok, tx, rest}
  end

  def is_coinbase?(tx_in) do
    OutPoint.is_coinbase?(tx_in.previous_output)
  end
end
