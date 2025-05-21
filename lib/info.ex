defmodule AshCanonicalIdentity.Info do
  use Spark.InfoGenerator, extension: AshCanonicalIdentity, sections: [:canonical_identities]
end
