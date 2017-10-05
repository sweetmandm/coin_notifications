defmodule CoinPusher.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    job_queues = [
      Honeydew.queue_spec(:rpc),
      Honeydew.worker_spec(:rpc, {CoinPusher.RPC, [Honeydew.FailureMode.Retry]}, num: 5, init_retry_secs: 4),

      Honeydew.queue_spec(:rawblock_parse),
      Honeydew.worker_spec(:rawblock_parse, {CoinPusher.ZMQRawBlock, [Honeydew.FailureMode.Retry]}, num: 1, init_retry_secs: 2),

      Honeydew.queue_spec(:rawtx_parse),
      Honeydew.worker_spec(:rawtx_parse, {CoinPusher.ZMQRawTx, [Honeydew.FailureMode.Abandon]}, num: 5)
    ]

    blockchain_workers = [
      worker(CoinPusher.BlockchainState, [&CoinPusher.Blockchain.fetch_initial_blocks/1]),
    ]

    zmq_workers = [
      worker(CoinPusher.ZMQClient, [zmq_address(), zmq_port()], function: :init)
    ]

    children = job_queues ++ blockchain_workers ++ zmq_workers
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
