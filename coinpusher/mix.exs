defmodule CoinPusher.Mixfile do
  use Mix.Project

  def project do
    [
      app: :coinpusher,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      #mod: {CoinPusher.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:chumak, github: "zeromq/chumak"}
    ]
  end
end
