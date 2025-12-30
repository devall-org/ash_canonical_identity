spark_locals_without_parens = [
  get_action: 1,
  list_action: 1,
  unoptimized_list_limit: 1,
  all_tenants?: 1,
  identity: 1,
  identity: 2,
  name: 1,
  nils_distinct?: 1,
  where: 1
]

[
  import_deps: [:spark, :reactor, :ash, :ash_postgres],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  plugins: [Spark.Formatter],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
