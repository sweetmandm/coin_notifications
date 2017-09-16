defmodule CoinPusher.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      Honeydew.queue_spec(:rpc),
      Honeydew.worker_spec(:rpc, {CoinPusher.RPC, []}, num: 5, init_retry_secs: 4),
      Honeydew.queue_spec(:rawblock_parse),
      Honeydew.worker_spec(:rawblock_parse, {CoinPusher.ZMQRawBlock, []}, num: 5, init_retry_secs: 4),
      Honeydew.queue_spec(:rawtx_parse),
      Honeydew.worker_spec(:rawtx_parse, {CoinPusher.ZMQRawTx, []}, num: 5, init_retry_secs: 4),
      worker(CoinPusher.BlockchainState, [&CoinPusher.Blockchain.fetch_initial_blocks/1]),
      worker(CoinPusher.ZMQClient, [zmq_address(), zmq_port()], function: :init)
    ]

    opts = [strategy: :one_for_one, name: CoinPusher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp zmq_address do
    Application.get_env(:coinpusher, :zmq_address)
    |> to_charlist
  end

  defp zmq_port do
    Application.get_env(:coinpusher, :zmq_port)
    |> Integer.parse
    |> elem(0)
  end
end
