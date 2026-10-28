defmodule AshCanonicalIdentity.TransformerOrderTest do
  use ExUnit.Case, async: true

  # AshPaperTrail의 AddTemporalInlineAttributes처럼 BelongsToAttribute보다 먼저 실행돼야 하는 transformer.
  defmodule BeforeBelongsToAttribute do
    use Spark.Dsl.Transformer

    def before?(Ash.Resource.Transformers.BelongsToAttribute), do: true
    def before?(_), do: false

    def transform(dsl_state), do: {:ok, dsl_state}
  end

  defmodule BeforeBelongsToAttributeExtension do
    use Spark.Dsl.Extension, transformers: [BeforeBelongsToAttribute]
  end

  test "BelongsToAttribute보다 먼저 실행되는 transformer가 있어도 belongs_to identity를 만든다" do
    defmodule Comment do
      use Ash.Resource,
        domain: AshCanonicalIdentity.Test.Domain,
        data_layer: Ash.DataLayer.Ets,
        extensions: [AshCanonicalIdentity, BeforeBelongsToAttributeExtension]

      attributes do
        uuid_primary_key :id
      end

      relationships do
        belongs_to :post, AshCanonicalIdentity.Test.Post, allow_nil?: false
      end

      canonical_identities do
        identity [:post]
      end
    end

    assert [%{name: :post, keys: [:post_id]}] = Ash.Resource.Info.identities(Comment)
  end
end
