defmodule CoinPusher.RPCEnqueue do
  require Logger
  def get_raw_block(hash) when is_binary(hash) do
    call_result({:get_raw_block, [hash]})
  end

  def get_raw_transaction(hash) when is_binary(hash) do
    call_result({:get_raw_transaction, [hash]})
  end

  def get_best_block_hash do
    call_result(:get_best_block_hash)
  end

  def get_info do
    call_result(:get_info)
  end

  defp call_result(input) do
    case input |> enqueue do
      {:ok, result} -> result
      nil -> nil
    end
  end

  defp enqueue(input) do
    input
    |> Honeydew.async(:rpc, reply: true)
    |> Honeydew.yield
  end
end
