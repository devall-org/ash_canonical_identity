defmodule AshCanonicalIdentity.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_canonical_identity,
      version: "0.1.1",
      elixir: "~> 1.17",
      consolidate_protocols: Mix.env() not in [:dev, :test],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Generate identity, get_by action and code_interface for unique keys.",
      package: package(),
      source_url: "https://github.com/devall-org/ash_canonical_identity",
      homepage_url: "https://github.com/devall-org/ash_canonical_identity",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, ">= 0.0.0"},
      {:spark, ">= 0.0.0"},
      {:sourceror, ">= 0.0.0", only: [:dev, :test], optional: true},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "ash_canonical_identity",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/devall-org/ash_canonical_identity"
      }
    ]
  end
end
