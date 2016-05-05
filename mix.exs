defmodule ExCLI.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_cli,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark,   "~> 0.1", only: :dev},
     {:ex_doc,    "~> 0.11", only: :dev},
     {:mix_test_watch, "~> 0.2", only: :dev}]
  end
end
