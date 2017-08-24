defmodule CoinPusher.Mixfile do
  use Mix.Project

  def project do
    [
      app: :coinpusher,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      aliases: [espec: "espec --no-start"],
      preferred_cli_env: [espec: :test],
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:jsonrpc2, :poison, :shackle],
      mod: {CoinPusher.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:chumak, github: "zeromq/chumak"},
      {:jsonrpc2, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:shackle, "~> 0.5"},
      {:espec, "~> 1.4.5", only: :test}
    ]
  end
end
