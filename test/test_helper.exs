ExUnit.start()

{:ok, _} = AshCanonicalIdentity.Test.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(AshCanonicalIdentity.Test.Repo, :manual)
