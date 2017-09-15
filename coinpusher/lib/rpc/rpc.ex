defmodule CoinPusher.RPC do
  alias CoinPusher.{RPC.HTTPClient, RawBlock}

  @type rpc_result :: {:ok, %{error: any, id: integer, result: HTTPClient.json}}

  @spec get_raw_transaction(String.t) :: rpc_result
  def get_raw_transaction(hash) when is_binary(hash) do
    HTTPClient.call(url(), "getrawtransaction", [hash], [auth_header()])
  end

  @spec get_info :: rpc_result
  def get_info do
    HTTPClient.call(url(), "getinfo", [], [auth_header()])
  end

  @spec get_best_block_hash :: rpc_result
  def get_best_block_hash do
    HTTPClient.call(url(), "getbestblockhash", [], [auth_header()])
  end

  @spec get_raw_block(String.t) :: {:ok, %RawBlock{}}
  def get_raw_block(block_hash) do
    {:ok, %{"result" => raw}} = HTTPClient.call(url(), "getblock", [block_hash, false], [auth_header()])
    {:ok, data} = raw |> Base.decode16(case: :lower)
    RawBlock.parse(data)
  end

  defp auth_header do
    {"Authorization", "Basic #{rpc_auth_pair()}"}
  end

  defp rpc_auth_pair do
    "#{rpc_user()}:#{rpc_password()}" |> Base.encode64
  end

  defp rpc_user do
    Application.get_env(:coinpusher, :rpc_user)
  end

  defp rpc_password do
    Application.get_env(:coinpusher, :rpc_pass)
  end

  defp url do
    "#{rpc_address()}:#{rpc_port()}"
  end

  defp rpc_address do
    Application.get_env(:coinpusher, :rpc_address)
  end

  defp rpc_port do
    Application.get_env(:coinpusher, :rpc_port)
  end
end
