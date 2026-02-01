defmodule Mdpub.MixProject do
  use Mix.Project

  def project do
    [
      app: :mdpub,
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
      mod: {Mdpub.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.7"},
      {:plug, "~> 1.16"},
      {:earmark, "~> 1.4"},
      {:file_system, "~> 1.1"}
    ]
  end
end
