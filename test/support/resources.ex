defmodule AshCanonicalIdentity.Test.Post do
  use Ash.Resource,
    domain: AshCanonicalIdentity.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshCanonicalIdentity]

  postgres do
    table "posts"
    repo AshCanonicalIdentity.Test.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false, public?: true
    attribute :subtitle, :string, allow_nil?: true, public?: true
    attribute :category, :string, allow_nil?: true, public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  canonical_identities do
    identity [:title]
    identity [:title], name: :published_title, where: expr(category == "published")
    identity [:subtitle], nils_distinct?: false
    identity [:subtitle, :category], nils_distinct?: false
  end
end

defmodule AshCanonicalIdentity.Test.PostTag do
  use Ash.Resource,
    domain: AshCanonicalIdentity.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshCanonicalIdentity]

  postgres do
    table "post_tags"
    repo AshCanonicalIdentity.Test.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :tag, :string, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  relationships do
    belongs_to :post, AshCanonicalIdentity.Test.Post, allow_nil?: false, public?: true
  end

  canonical_identities do
    identity [:post, :tag]
  end
end

defmodule AshCanonicalIdentity.Test.ReadActionsDisabled do
  use Ash.Resource,
    data_layer: :embedded,
    extensions: [AshCanonicalIdentity]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :category, :string, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read]
  end

  canonical_identities do
    generate_read_actions? false

    identity [:name]
    identity [:category], get_action: :get_by_category, list_action: :list_by_category
  end
end

defmodule AshCanonicalIdentity.Test.Domain do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource AshCanonicalIdentity.Test.Post
    resource AshCanonicalIdentity.Test.PostTag
  end
end
