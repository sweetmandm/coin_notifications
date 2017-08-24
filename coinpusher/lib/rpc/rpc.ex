defmodule CoinPusher.RPC do
  alias CoinPusher.RPC.HTTPClient

  #@type rpc_result %{error: any, id: integer, result: HTTPClient.json}
  @type rpc_result :: %{error: any, id: integer, result: HTTPClient.json}

  @spec get_raw_transaction(String.t) :: rpc_result
  def get_raw_transaction(hash) do
    HTTPClient.call("http://127.0.0.1:18332/", "getrawtransaction", [hash], [auth_header()])
  end

  @spec get_info :: rpc_result
  def get_info do
    HTTPClient.call("http://127.0.0.1:18332/", "getinfo", [], [auth_header()])
  end

  @spec get_best_block_hash :: rpc_result
  def get_best_block_hash do
    HTTPClient.call("http://127.0.0.1:18332/", "getbestblockhash", [], [auth_header()])
  end

  defp auth_header do
    {"Authorization", "Basic #{rpc_pair()}"}
  end

  defp rpc_pair do
    "#{rpc_user()}:#{rpc_password()}" |> Base.encode64
  end

  defp rpc_user do
    Application.get_env(:coinpusher, :rpc_user)
  end

  defp rpc_password do
    Application.get_env(:coinpusher, :rpc_pass)
  end
end
