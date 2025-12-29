defmodule AshCanonicalIdentity.Test.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
    end

    create unique_index(:posts, [:title])

    create table(:post_tags, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :post_id, references(:posts, type: :uuid), null: false
      add :tag, :string, null: false
    end

    create unique_index(:post_tags, [:post_id, :tag])
  end
end
