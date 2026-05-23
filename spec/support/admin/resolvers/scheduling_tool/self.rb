require "graphql"
require "support/admin/resolvers/scheduling_tool/associate"

module SpecSchemas
  module Admin
    module Resolvers
      module SchedulingTool
        # Counterpart of admin-back's Resolvers::SchedulingTool::Self — the
        # `schedulingTool` entry point on the Query root. Returns itself and
        # groups the scheduling-tool sub-resolvers (`associate`) underneath.
        class Self < GraphQL::Schema::Resolver
          class Objects < GraphQL::Schema::Object
            graphql_name "SchedulingToolActions"
            field :associate, resolver: SchedulingTool::Associate
          end

          type Objects, null: false

          def resolve = self
        end
      end
    end
  end
end
