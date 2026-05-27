require "graphql"
require "support/scheduling/resolvers/associate"

module SpecSchemas
  module Scheduling
    class Query < GraphQL::Schema::Object
      field :associate, resolver: Resolvers::Associate
    end

    # Standalone, fully executable remote (scheduling-tool) schema. The
    # wrapper model talks to it through GraphQL::Client + a local-execute
    # adapter, so the e2e spec exercises a real GraphQL server rather than
    # a canned response. Kept separate from the admin-back schema so the
    # wrapper can use the nested-action shape (`associate { search }`).
    class Schema < GraphQL::Schema
      query Query
    end
  end
end
