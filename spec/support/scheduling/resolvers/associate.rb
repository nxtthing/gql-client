require "graphql"
require "support/scheduling/types/associate"
require "support/scheduling/data/associate/store"

module SpecSchemas
  module Scheduling
    module Resolvers
      # Resolves the `associate` entry point on the Query root — a thin
      # grouping resolver that returns itself and exposes `search`
      # underneath, mirroring how the admin side nests AssociateActions in
      # its resolver.
      class Associate < GraphQL::Schema::Resolver
        class Actions < GraphQL::Schema::Object
          graphql_name "AssociateActions"

          field :search, Types::Associate, null: false

          # The spec seeds a single associate; `search` serves it from the
          # store. A list/pagination shape isn't needed for these specs.
          def search
            Data::Associate::Store.associates.first
          end
        end

        type Actions, null: false

        def resolve = self
      end
    end
  end
end
