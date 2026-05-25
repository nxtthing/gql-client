require "graphql"

module SpecSchemas
  module Scheduling
    module Types
      # Mirrors nxt-scheduling-back's Types::Admin::AssociateTenancySkills.
      class AssociateTenancySkills < GraphQL::Schema::Object
        field :tenancy_id, GraphQL::Types::String, null: false
        field :task_names, [GraphQL::Types::String], null: false
      end
    end
  end
end
