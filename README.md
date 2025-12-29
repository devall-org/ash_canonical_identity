# AshCanonicalIdentity

Generate identity, get_by/list_by actions and code_interface for unique keys.

## Installation

Add `ash_canonical_identity` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_canonical_identity, "~> 0.3.0"}
  ]
end
```

## Usage

```elixir
defmodule PostTag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshCanonicalIdentity]

  attributes do
    uuid_primary_key :id
    attribute :tag, :string, allow_nil?: false, public?: true
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

The `identity [:post, :tag]` generates:

- `get_by_post_tag(post_id, tag)` - returns single record
- `list_by_post_tag(values)` - returns multiple records

### Options

```elixir
canonical_identities do
  identity [:post, :tag],
    name: :custom_name,           # default: :auto (generates :post_tag)
    get_action: :custom_get,      # default: :auto (generates :get_by_post_tag), false to disable
    list_action: :custom_list,    # default: :auto (generates :list_by_post_tag), false to disable
    where: expr(active == true),  # optional filter
    nils_distinct?: true          # default: true
end
```

### Examples

```elixir
# get_by - single record
PostTag.get_by_post_tag!(post_id, "elixir")

# list_by - multiple records (tuple order matches get_by args)
PostTag.list_by_post_tag!([
  {post1_id, "elixir"},
  {post2_id, "phoenix"}
])
```

### Generated Code Equivalent

The `identity [:post, :tag]` has the same effect as:

```elixir
identities do
  identity :post_tag, [:post_id, :tag]
end

actions do
  read :get_by_post_tag do
    get? true
    argument :post_id, :uuid, allow_nil?: true
    argument :tag, :string, allow_nil?: true
    filter expr(post_id == ^arg(:post_id) and tag == ^arg(:tag))
  end

  read :list_by_post_tag do
    argument :values, {:array, :term}, allow_nil?: false
    prepare {AshCanonicalIdentity.ListPreparation, attr_names: [:post_id, :tag], where: nil}
  end
end

code_interface do
  define :get_by_post_tag, args: [:post_id, :tag]
  define :list_by_post_tag, args: [:values]
end
```

## License

MIT
