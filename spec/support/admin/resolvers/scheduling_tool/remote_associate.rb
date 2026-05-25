require "graphql"
require "support/scheduling/types/associate"
require "support/scheduling/data/associate/store"

module SpecSchemas
  module Admin
    module Resolvers
      module SchedulingTool
        # Resolves the `remoteAssociate` Query-root field — exposes the
        # remote-shaped Associate directly (no proxying), so the
        # transform_response specs can run remote-shaped queries against the
        # admin schema. Reuses SchedulingTool::DataStore.
        class RemoteAssociate < GraphQL::Schema::Resolver
          type SpecSchemas::Scheduling::Types::Associate, null: false

          def resolve
            SpecSchemas::Scheduling::Data::Associate::Store.associates.first
          end
        end
      end
    end
  end
end
