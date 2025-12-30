defmodule Mix.Tasks.AshCanonicalIdentity.GenerateDocs do
  @moduledoc """
  Generates DSL documentation for AshCanonicalIdentity.
  """
  use Mix.Task

  @shortdoc "Generates DSL documentation"
  def run(_) do
    Mix.Task.run("compile")

    File.mkdir_p!("documentation/dsls")

    docs =
      Spark.CheatSheet.cheat_sheet(AshCanonicalIdentity)

    File.write!("documentation/dsls/ash-canonical-identity.md", docs)

    Mix.shell().info("Generated documentation/dsls/ash-canonical-identity.md")
  end
end
