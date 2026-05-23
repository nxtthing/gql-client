require "graphql"
require "support/admin/resolvers/scheduling_tool/associates/search"

module SpecSchemas
  module Admin
    module Resolvers
      module SchedulingTool
        # Counterpart of admin-back's Resolvers::SchedulingTool::Associate: a
        # thin grouping resolver that returns itself and exposes `search`
        # underneath. The real proxy work happens in the Search resolver.
        class Associate < GraphQL::Schema::Resolver
          class Actions < GraphQL::Schema::Object
            graphql_name "AssociateActions"
            field :search, resolver: Associates::Search
          end

          type Actions, null: false

          def resolve = self
        end
      end
    end
  end
end
