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
      aliases: aliases(),
      description:
        "Generate identity, get_by/list_by actions and code_interface for unique keys.",
      package: package(),
      source_url: "https://github.com/devall-org/ash_canonical_identity",
      homepage_url: "https://github.com/devall-org/ash_canonical_identity",
      docs: docs(),
      spark: spark_opts()
    ]
  end

  def cli do
    [
      preferred_envs: ["test.reset": :test]
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

  defp aliases do
    [
      "test.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "test"]
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

  defp docs do
    [
      main: "readme",
      extras: [
        {"README.md", title: "Home"},
        {"documentation/dsls/ash-canonical-identity.md", title: "DSL: AshCanonicalIdentity"}
      ],
      groups_for_extras: [
        DSLs: ~r'documentation/dsls'
      ],
      groups_for_modules: [
        Extensions: [
          AshCanonicalIdentity,
          AshCanonicalIdentity.Identity,
          AshCanonicalIdentity.Info
        ],
        Internals: [
          AshCanonicalIdentity.Transformer,
          AshCanonicalIdentity.ListPreparation
        ]
      ],
      spark: [
        extensions: [
          %{
            module: AshCanonicalIdentity,
            name: "AshCanonicalIdentity",
            target: "Ash.Resource",
            type: "Resource"
          }
        ]
      ],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({
          startOnLoad: false,
          theme: document.body.className.includes("dark") ? "dark" : "default"
        });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""

  defp spark_opts do
    [
      extensions: [AshCanonicalIdentity]
    ]
  end
end
