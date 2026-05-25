require "graphql"
require "support/types/tag"
require "support/types/tags_filter"
require "support/scheduling/types/associate_tenancy_skills"

module SpecSchemas
  module Scheduling
    module Types
      class Associate < GraphQL::Schema::Object
        description <<~DESC
          Mirrors nxt-scheduling-back's Types::Admin::Associate: `tags(filter:
          ByKeys)` returns rows carrying both key and value, `tenancySkills`
          returns its own object type. graphql_name `Associate` matches
          AssociateSchedulingTool.proxy_model.typename in the admin-back
          spec — the pin-lookup key.
        DESC

        field :id, GraphQL::Types::ID, null: false

        field :tags, [SpecSchemas::Types::Tag], null: false do
          argument :filter, SpecSchemas::Types::TagsFilter, required: true
        end

        field :tenancy_skills, [AssociateTenancySkills], null: false do
          argument :tenancy_ids, [GraphQL::Types::String], required: false
        end

        # `object` is the plain associate hash from Store.
        def tags(filter:)
          keys = filter[:keys]
          object[:tags].select { |tag| keys.include?(tag[:key]) }
        end

        def tenancy_skills(tenancy_ids: nil)
          rows = object[:tenancy_skills]
          rows = rows.select { |row| tenancy_ids.include?(row[:tenancy_id]) } if tenancy_ids
          rows
        end
      end
    end
  end
end
