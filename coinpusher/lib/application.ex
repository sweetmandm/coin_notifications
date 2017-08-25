defmodule CoinPusher.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(CoinPusher.NotificationsController, [:listeners]),
      worker(CoinPusher.ZMQClient, [zmq_address(), zmq_port()], function: :init)
    ]

    opts = [strategy: :one_for_one, name: CoinPusher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp rpc_address do
    zmq_address()
  end

  defp rpc_port do
    18332
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
