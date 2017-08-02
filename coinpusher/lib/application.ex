defmodule CoinPusher.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(CoinPusher.ZMQClient, [])
    ]

    opts = [strategy: :one_for_one, name: CoinPusher.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
