import Config

config :ash, :validate_domain_config_inclusion?, false

if config_env() == :test do
  config :ash_canonical_identity, AshCanonicalIdentity.Test.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "ash_canonical_identity_test",
    pool: Ecto.Adapters.SQL.Sandbox

  config :ash_canonical_identity,
    ecto_repos: [AshCanonicalIdentity.Test.Repo],
    ash_domains: [AshCanonicalIdentity.Test.Domain]
end
