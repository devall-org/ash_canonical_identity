defmodule AshCanonicalIdentity.Transformer do
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer
  alias Ash.Resource.Attribute
  alias Ash.Resource.Relationships.BelongsTo
  alias Ash.Resource.Builder

  def after?(Ash.Resource.Transformers.BelongsToAttribute), do: true
  def after?(_), do: false

  def before?(Ash.Resource.Transformers.GetByReadActions), do: true
  def before?(_), do: false

  def transform(dsl_state) do
    attrs =
      dsl_state
      |> Transformer.get_entities([:attributes])
      |> Enum.map(fn %Attribute{name: name, source: _source} ->
        {name, name}
      end)

    belongs_to_attrs =
      dsl_state
      |> get_belongs_toes()
      |> Enum.map(fn %BelongsTo{name: name, source_attribute: source_attribute} ->
        {name, source_attribute}
      end)

    name_to_attr_name_map = (attrs ++ belongs_to_attrs) |> Map.new()

    dsl_state
    |> Transformer.get_entities([:canonical_identities])
    |> Enum.reduce(
      {:ok, dsl_state},
      fn %AshCanonicalIdentity.Identity{
           attr_or_belongs_toes: attr_or_belongs_toes,
           all_tenants?: all_tenants?,
           name: name,
           action: action_name,
           where: where,
           nils_distinct?: nils_distinct?
         },
         {:ok, dsl_state} ->
        name_joined = Enum.join(attr_or_belongs_toes, "_") |> String.to_atom()
        name = if name == :auto, do: name_joined, else: name

        attr_names = attr_or_belongs_toes |> Enum.map(&Map.fetch!(name_to_attr_name_map, &1))
        opts = [all_tenants?: all_tenants?, where: where, nils_distinct?: nils_distinct?]

        {:ok, dsl_state} = dsl_state |> Builder.add_identity(name, attr_names, opts)

        if action_name do
          action_name = if action_name == :auto, do: :"get_by_#{name_joined}", else: action_name
          {:ok, dsl_state |> add_action(action_name, attr_names, opts)}
        else
          {:ok, dsl_state}
        end
      end
    )
  end

  defp get_belongs_toes(%{} = dsl_state) do
    multitenant_attr = dsl_state |> Transformer.get_option([:multitenancy], :attribute)

    dsl_state
    |> Transformer.get_entities([:relationships])
    |> Enum.filter(fn
      %BelongsTo{source_attribute: source_attribute} -> source_attribute != multitenant_attr
      %{} -> false
    end)
  end

  defp add_action(dsl_state, action_name, attr_names, opts) do
    import Ash.Expr

    where = opts |> Keyword.fetch!(:where)
    nils_distinct? = opts |> Keyword.fetch!(:nils_distinct?)

    all_attrs = dsl_state |> Transformer.get_entities([:attributes])

    action_arguments =
      attr_names
      |> Enum.map(fn attr_name ->
        %{type: type} = all_attrs |> Enum.find(&(&1.name == attr_name))

        Transformer.build_entity!(Ash.Resource.Dsl, [:actions, :read], :argument,
          name: attr_name,
          type: type,
          allow_nil?: false
        )
      end)

    action_filters =
      attr_names
      |> Enum.map(fn attr_name ->
        case nils_distinct? do
          true -> expr(^ref(attr_name) == ^arg(attr_name))
          false -> expr(nil_safe_equals(^ref(attr_name), ^arg(attr_name)))
        end
      end)
      |> then(fn filters ->
        case where do
          nil -> filters
          where -> [where | filters]
        end
      end)
      |> Enum.map(&%Ash.Resource.Dsl.Filter{filter: &1})

    dsl_state
    |> Builder.add_action(:read, action_name,
      get?: true,
      arguments: action_arguments,
      filters: action_filters
    )
    |> Builder.add_interface(action_name,
      args: attr_names
    )
    |> then(fn {:ok, dsl_state} -> dsl_state end)
  end
end
