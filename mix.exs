defmodule MicroScaffoldExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :micro_scaffold_example,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MicroScaffoldExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:micro_phoenix, path: "../micro_phoenix"},
      {:ecto_sqlite3, "~> 0.21"}
    ]
  end
end
