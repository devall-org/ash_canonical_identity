defmodule AshCanonicalIdentity do
  defmodule Identity do
    defstruct [
      :attr_or_belongs_toes,
      :all_tenants?,
      :name,
      :get_action,
      :list_action,
      :where,
      :nils_distinct?,
      :max_list_size,
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
      get_action: [
        type: :atom,
        default: :auto,
        doc: """
        Name for get_by action. If :auto, generates get_by_cart_product. If false, no action created.
        """
      ],
      list_action: [
        type: :atom,
        default: :auto,
        doc: """
        Name for list_by action. If :auto, generates list_by_cart_product. If false, no action created.
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
      ],
      max_list_size: [
        type: :pos_integer,
        default: 100,
        doc: """
        Maximum number of tuples allowed for list_by action. Raises ArgumentError if exceeded.

        ## Why this limit exists

        PostgreSQL doesn't natively support tuple lists in the IN operator (e.g., `WHERE (a, b) IN ((1, 2), (3, 4))`).
        While single-column IN queries use efficient `= ANY(array)` syntax, multi-column queries must be expanded into OR conditions:

        ```sql
        WHERE ((a = 1 AND b = 2) OR (a = 3 AND b = 4) OR ...)
        ```

        Large OR chains can impact query performance and planning time. This limit prevents accidentally creating
        queries with thousands of OR conditions. If you need to query more records, consider:

        - Increasing this limit if your use case requires it
        - Using a temporary table or JOIN approach for very large datasets
        - Splitting the query into multiple batches
        """
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
