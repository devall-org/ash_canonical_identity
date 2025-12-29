# Rules for working with AshCanonicalIdentity

## Purpose

AshCanonicalIdentity is an Ash extension that automatically generates identity, get_by/list_by read actions, and code_interface for unique keys.

## Setup

```elixir
defmodule MyApp.MyResource do
  use Ash.Resource,
    extensions: [AshCanonicalIdentity]
end
```

## Basic Usage

Define an identity in the `canonical_identities` block to automatically generate an identity, get_by/list_by actions, and code_interface:

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

This generates:
- `get_by_post_tag(post_id, tag)` - returns single record
- `list_by_post_tag(values)` - returns multiple records

### Usage Examples

```elixir
# get_by - single record lookup
PostTag.get_by_post_tag!(post_id, "elixir")

# list_by - bulk lookup (tuple order matches get_by args)
PostTag.list_by_post_tag!([
  {post1_id, "elixir"},
  {post2_id, "phoenix"}
])
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

### get_action

Specify the get_by action and code_interface name:

```elixir
canonical_identities do
  identity [:post, :tag], get_action: :find_by_post_and_tag
end
```

`:auto` (default): Automatically generates `get_by_cart_product` from `[:cart, :product]`
`false`: Don't create get_by action and code_interface

### list_action

Specify the list_by action and code_interface name:

```elixir
canonical_identities do
  identity [:post, :tag], list_action: :find_all_by_post_and_tag
end
```

`:auto` (default): Automatically generates `list_by_cart_product` from `[:cart, :product]`
`false`: Don't create list_by action and code_interface

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
- When you need to bulk fetch records by composite keys (list_by)
- When dealing with composite unique constraints
- When working with unique constraints that include belongs_to relationships

## Best Practices

- Use relationship names (`:post`) instead of foreign key names (`:post_id`) when referencing belongs_to relationships
- Retrieve single record using: `Domain.get_by_post_tag!(post_id, tag)`
- Retrieve multiple records using: `Domain.list_by_post_tag!([{id1, t1}, {id2, t2}])` (tuple order matches get_by args)
- Explicitly set `name:` option if the identity name isn't clear
- Set `get_action: false` or `list_action: false` if you don't need the respective action
