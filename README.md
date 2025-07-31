# AshCanonicalIdentity

Generate identity, get_by action and code_interface for unique keys.

## Installation

Add `ash_canonical_identity` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_canonical_identity, "~> 0.2.0"}
  ]
end
```

## Usage

```elixir
defmodule Post do
  use Ash.Resource,
    data_layer: Ash.DataLayer.Postgres,
    extensions: [AshCanonicalIdentity]


  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end
end

defmodule PostTag do
  use Ash.Resource,
    data_layer: Ash.DataLayer.Postgres,
    extensions: [AshCanonicalIdentity]


  attributes do
    uuid_primary_key :id

    attribute :tag, :string, allow_nil?: true, public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  relationships do
    belongs_to :post, Post, allow_nil?: false, public?: true
  end

  canonical_identities do
    identity [:post, :tag]
  end
end
```

The `identity [:post, :tag]` set in `canonical_identities` above has the same effect as the code below:

```elixir
identities do
  identity :post_tag, [:post_id, :tag]
end

actions do
  read :get_by_post_tag do
    get? true
    argument :post_id, :uuid, allow_nil?: false
    argument :tag, :string, allow_nil?: false
    filter expr(post_id == ^arg(:post_id))
    filter expr(tag == ^arg(:tag))
  end
end

code_interface do
  define :get_by_post_tag, args: [:post_id, :tag]
end
```

## License

MIT