# Rules for working with AshCanonicalIdentity

## Purpose

AshCanonicalIdentity is an Ash extension that automatically generates identity, get_by read action, and code_interface for unique keys.

## Setup

```elixir
defmodule MyApp.MyResource do
  use Ash.Resource,
    extensions: [AshCanonicalIdentity]
end
```

## Basic Usage

Define an identity in the `canonical_identities` block to automatically generate an identity, get_by action, and code_interface:

```elixir
defmodule PostTag do
  use Ash.Resource,
    extensions: [AshCanonicalIdentity]

  attributes do
    uuid_primary_key :id
    attribute :tag, :string
  end

  relationships do
    belongs_to :post, Post
  end

  canonical_identities do
    identity [:post, :tag]
  end
end
```

This has the same effect as writing:

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

## Options

### name

Specify the identity name:

```elixir
canonical_identities do
  identity [:post, :tag], name: :unique_post_tag
end
```

`:auto` (default): Automatically generates `cart_product` from `[:cart, :product]`

### action

Specify the action and code_interface name:

```elixir
canonical_identities do
  identity [:post, :tag], action: :find_by_post_and_tag
end
```

`:auto` (default): Automatically generates `get_by_cart_product` from `[:cart, :product]`
`false`: Don't create action and code_interface

### all_tenants?

Specify if the identity is unique across all tenants in a multi-tenant environment:

```elixir
canonical_identities do
  identity [:email], all_tenants?: true
end
```

### where

Specify a filter for conditional uniqueness:

```elixir
canonical_identities do
  identity [:email], where: expr(deleted_at == nil)
end
```

### nils_distinct?

Specify if `nil` values should always be treated as distinct (default: `true`):

```elixir
canonical_identities do
  identity [:post, :tag], nils_distinct?: false
end
```

## When to Use

- When you need a get_by pattern for unique keys
- When dealing with composite unique constraints
- When working with unique constraints that include belongs_to relationships

## Best Practices

- Use relationship names (`:post`) instead of foreign key names (`:post_id`) when referencing belongs_to relationships
- Retrieve using the generated code_interface: `Domain.get_by_post_tag!(post_id, tag)`
- Explicitly set `name:` option if the identity name isn't clear
- Set `action: false` if you don't need the action

