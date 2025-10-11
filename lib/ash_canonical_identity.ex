defmodule AshCanonicalIdentity do
  defmodule Identity do
    defstruct [
      :attr_or_belongs_toes,
      :all_tenants?,
      :name,
      :action,
      :where,
      :nils_distinct?,
      :select,
      :__spark_metadata__
    ]
  end

  @identity %Spark.Dsl.Entity{
    name: :identity,
    describe: """
    An entity that canonically configures identities, actions, and code_interface.
    """,
    imports: [Ash.Expr],
    examples: [
      "identity [:company, :role]"
    ],
    target: Identity,
    args: [:attr_or_belongs_toes],
    schema: [
      attr_or_belongs_toes: [
        type: {:wrap_list, :atom},
        doc: "List of attributes/relationships that make up the identity (excluding tenant)"
      ],
      all_tenants?: [
        type: :boolean,
        default: false,
        doc: "Whether it is unique across all tenants."
      ],
      name: [
        type: :atom,
        default: :auto,
        doc: """
        Name to be used for the identity.
        If :auto, it will be generated as cart_product when attr_or_belongs_toes is [:cart, :product].
        """
      ],
      action: [
        type: :atom,
        default: :auto,
        doc: """
        Name to be used in actions and code_interface.
        If :auto, it will be generated as get_by_cart_product when attr_or_belongs_toes is [:cart, :product].
        If false, no action will be created.
        """
      ],
      where: [
        type: :any,
        doc:
          "A filter that expresses only matching records are unique on the provided keys. Ignored on embedded resources."
      ],
      nils_distinct?: [
        type: :boolean,
        default: true,
        doc:
          "Whether or not `nil` values are considered always distinct from eachother. `nil` values won't conflict with eachother unless you set this option to `false`."
      ]
    ]
  }

  @canonical_identities %Spark.Dsl.Section{
    name: :canonical_identities,
    describe: """
    A section that canonically configures identities, actions, and code_interface based on identity.
    """,
    entities: [@identity]
  }

  use Spark.Dsl.Extension,
    sections: [@canonical_identities],
    transformers: [AshCanonicalIdentity.Transformer]
end
