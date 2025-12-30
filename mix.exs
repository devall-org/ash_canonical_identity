defmodule AshCanonicalIdentity.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_canonical_identity,
      version: "0.3.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() not in [:dev, :test],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Generate identity, get_by/list_by actions and code_interface for unique keys.",
      package: package(),
      source_url: "https://github.com/devall-org/ash_canonical_identity",
      homepage_url: "https://github.com/devall-org/ash_canonical_identity",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:ash_postgres, ">= 0.0.0"},
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
