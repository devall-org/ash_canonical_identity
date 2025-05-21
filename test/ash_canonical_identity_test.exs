# defmodule AshCanonicalIdentityTest.Case do
#   use ExUnit.Case, async: true

#   alias __MODULE__.{Post, PostTag, Domain}

#   defmodule Post do
#     use Ash.Resource,
#       domain: Domain,
#       data_layer: Ash.DataLayer.Postgres,
#       extensions: [AshCanonicalIdentity]

#     attributes do
#       uuid_primary_key :id

#       attribute :title, :string, allow_nil?: false, public?: true
#     end

#     actions do
#       defaults [:read, :destroy, create: :*, update: :*]
#     end
#   end

#   defmodule PostTag do
#     use Ash.Resource,
#       domain: Domain,
#       data_layer: Ash.DataLayer.Postgres,
#       extensions: [AshCanonicalIdentity]

#     attributes do
#       uuid_primary_key :id

#       attribute :tag, :string, allow_nil?: true, public?: true
#     end

#     actions do
#       defaults [:read, :destroy, create: :*, update: :*]
#     end

#     relationships do
#       belongs_to :post, Post, allow_nil?: false, public?: true
#     end

#     canonical_identities do
#       identity [:post, :tag]
#     end
#   end

#   defmodule Domain do
#     use Ash.Domain, validate_config_inclusion?: false

#     resources do
#       resource Post
#       resource PostTag
#     end
#   end

#   test "canonical_identity" do
#     assert %{} = Ash.Resource.Info.identity(PostTag, :post_tag)
#     assert %{get?: true} = Ash.Resource.Info.action(PostTag, :get_by_post_tag)
#     assert %{} = Ash.Resource.Info.interface(PostTag, :get_by_post_tag)
#   end
# end
