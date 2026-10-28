defmodule AshCanonicalIdentity.TransformerOrderTest do
  use ExUnit.Case, async: true

  defmodule Domain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      allow_unregistered? true
    end
  end

  defmodule User do
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Ets

    actions do
      defaults [:read]
    end

    attributes do
      uuid_primary_key :id
    end
  end

  # Mirrors AshPaperTrail's AddTemporalInlineAttributes ordering constraint.
  defmodule BeforeBelongsToAttribute do
    use Spark.Dsl.Transformer

    def before?(Ash.Resource.Transformers.BelongsToAttribute), do: true
    def before?(_), do: false

    def transform(dsl_state), do: {:ok, dsl_state}
  end

  defmodule BeforeBelongsToAttributeExtension do
    use Spark.Dsl.Extension, transformers: [BeforeBelongsToAttribute]
  end

  test "generates identities and read actions from belongs_to source attributes" do
    defmodule AttributeKeyComment do
      use Ash.Resource,
        domain: Domain,
        data_layer: Ash.DataLayer.Ets,
        extensions: [AshCanonicalIdentity, BeforeBelongsToAttributeExtension]

      def testing_identities, do: true

      attributes do
        uuid_primary_key :id
      end

      relationships do
        belongs_to :user, User, allow_nil?: false, attribute_type: :uuid
      end

      canonical_identities do
        identity [:user_id]
      end
    end

    assert [%{name: :user_id, keys: [:user_id]}] =
             Ash.Resource.Info.identities(AttributeKeyComment)

    assert %{type: Ash.Type.UUID} =
             AttributeKeyComment
             |> Ash.Resource.Info.action(:get_by_user_id)
             |> Map.fetch!(:arguments)
             |> Enum.find(&(&1.name == :user_id))

    assert :user_id in Ash.Resource.Info.action_inputs(AttributeKeyComment, :get_by_user_id)
    assert function_exported?(AttributeKeyComment, :get_by_user_id, 1)
    assert function_exported?(AttributeKeyComment, :list_by_user_id, 1)
  end

  test "resolves belongs_to names after their attributes have been generated" do
    defmodule RelationshipKeyComment do
      use Ash.Resource,
        domain: Domain,
        data_layer: Ash.DataLayer.Ets,
        extensions: [BeforeBelongsToAttributeExtension, AshCanonicalIdentity]

      def testing_identities, do: true

      attributes do
        uuid_primary_key :id
      end

      relationships do
        belongs_to :user, User, allow_nil?: false, attribute_type: :uuid
      end

      canonical_identities do
        identity [:user]
      end
    end

    assert [%{name: :user, keys: [:user_id]}] =
             Ash.Resource.Info.identities(RelationshipKeyComment)

    assert %{name: :user_id} = Ash.Resource.Info.attribute(RelationshipKeyComment, :user_id)
    assert function_exported?(RelationshipKeyComment, :get_by_user, 1)
  end

  test "validates generated action names alongside explicitly declared actions" do
    assert_raise Spark.Error.DslError, ~r/Multiple actions.*get_by_title/s, fn ->
      defmodule ConflictingActions do
        use Ash.Resource,
          domain: Domain,
          data_layer: Ash.DataLayer.Ets,
          extensions: [AshCanonicalIdentity]

        attributes do
          uuid_primary_key :id
          attribute :title, :string
        end

        actions do
          read :get_by_title
        end

        canonical_identities do
          identity [:title]
        end
      end
    end
  end
end
