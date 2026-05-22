require "graphql"
require "support/scheduling_tool/types/associate"

module SpecSchemas
  module SchedulingTool
    module Types
      class AssociateActions < GraphQL::Schema::Object
        description "Nested-action entry point — the shape admin-back wrappers hit (`associate { search }`)."
        field :search, Associate, null: false
      end
    end
  end
end
