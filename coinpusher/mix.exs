defmodule CoinPusher.Mixfile do
  use Mix.Project

  def project do
    [
      app: :coinpusher,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      preferred_cli_env: [espec: :test],
      deps: deps()
    ]
  end

  def application do
    [
      mod: {CoinPusher.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:chumak, github: "zeromq/chumak"},
      {:espec, "~> 1.4.5", only: :test}
    ]
  end
end
