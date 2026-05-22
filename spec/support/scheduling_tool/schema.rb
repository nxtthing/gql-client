require "graphql"
require "support/scheduling_tool/types/associate_actions"

module SpecSchemas
  module SchedulingTool
    class Query < GraphQL::Schema::Object
      field :associate, Types::AssociateActions, null: false
    end

    # Standalone remote (scheduling-tool) schema, loaded by proxy_e2e_spec
    # via GraphQL::Client. Kept separate from the admin-back schema so the
    # wrapper can use the nested-action shape (`associate { search }`)
    # without clashing with the admin side's bare `associate` field.
    class Schema < GraphQL::Schema
      query Query
    end
  end
end
