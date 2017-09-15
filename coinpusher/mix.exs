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
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env)
    ]
  end

  def application do
    [
      applications: [:poison, :hackney],
      mod: {CoinPusher.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:chumak, github: "zeromq/chumak"},
      {:poison, "~> 3.1"},
      {:hackney, "~> 1.7"},
      {:honeydew, "~> 1.0.1"},
      {:espec, "~> 1.4.5", only: :test},
      {:ex_machina, "~> 2.1", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "spec/support"]
  defp elixirc_paths(_), do: ["lib"]
end
