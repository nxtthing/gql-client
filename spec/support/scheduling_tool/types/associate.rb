require "graphql"
require "support/types/tag"
require "support/types/tags_filter"

module SpecSchemas
  module SchedulingTool
    module Types
      class Associate < GraphQL::Schema::Object
        description <<~DESC
          Remote (scheduling-tool) shape: one `tags(filter:)` field the rebuilt
          admin-back query calls several times under different aliases. Used by
          both spec schemas — the standalone scheduling-tool schema and, as
          `remoteAssociate`, the admin-back schema (so transform_response specs
          can parse remote-shaped queries). graphql_name `Associate` matches
          AssociateSchedulingTool.proxy_model.typename, the pin-lookup key.
        DESC

        field :id, GraphQL::Types::ID, null: false
        field :tags, [SpecSchemas::Types::Tag], null: false do
          argument :filter, SpecSchemas::Types::TagsFilter, required: true
        end
        # Lets the frontend alias the same field twice with different args
        # (`a: tenancySkills(t1) b: tenancySkills(t2)`).
        field :tenancy_skills, [SpecSchemas::Types::Tag], null: false do
          argument :tenancy_ids, [GraphQL::Types::String], required: false
        end
      end
    end
  end
end
