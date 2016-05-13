defmodule ExCLI.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :ex_cli,
     version: @version,
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "Library to build CLI applications",
     source_url: "https://github.com/tuvistavie/ex_cli",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     test_coverage: [tool: ExCoveralls],
     deps: deps,
     docs: [source_ref: "#{@version}", extras: ["README.md"], main: "readme"]]
  end

  defp elixirc_paths(:dev),  do: elixirc_paths(:test)
  defp elixirc_paths(:test), do: ["sample", "lib"]
  defp elixirc_paths(_all),  do: ["lib"]


  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:excoveralls, "~> 0.4", only: :test},
     {:earmark,   "~> 0.1", only: :docs},
     {:ex_doc,    "~> 0.11", only: :docs}]
  end

  defp package do
    [
      maintainers: ["Daniel Perez"],
      files: ["lib", "mix.exs", "README.md"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/tuvistavie/ex_cli",
        "Docs" => "http://hexdocs.pm/ex_cli/"
      }
    ]
  end
end
