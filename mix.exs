defmodule Mdpub.MixProject do
  use Mix.Project

  def project do
    [
      app: :mdpub,
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Mdpub.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:bandit, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:earmark, "~> 1.4"},
      {:file_system, "~> 1.1"},
      {:yaml_elixir, "~> 2.11"},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild mdpub"],
      "assets.deploy": ["esbuild mdpub --minify", "phx.digest"]
    ]
  end
end
