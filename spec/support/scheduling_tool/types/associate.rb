require "graphql"
require "support/types/tag"
require "support/types/tags_filter"

module SpecSchemas
  module SchedulingTool
    module Types
      class Associate < GraphQL::Schema::Object
        description <<~DESC
          Remote (scheduling-tool) shape: one `tags(filter:)` field the rebuilt
          admin-back query calls several times under different aliases, plus
          an argument-filtered `tenancySkills`. Fully resolvable — fed from
          DataStore — so the e2e spec runs a real GraphQL server here.
          graphql_name `Associate` matches AssociateSchedulingTool.proxy_model
          .typename, the pin-lookup key.
        DESC

        field :id, GraphQL::Types::ID, null: false

        field :tags, [SpecSchemas::Types::Tag], null: false do
          argument :filter, SpecSchemas::Types::TagsFilter, required: true
        end

        field :tenancy_skills, [SpecSchemas::Types::Tag], null: false do
          argument :tenancy_ids, [GraphQL::Types::String], required: false
        end

        # `object` is the plain associate hash from DataStore.
        def tags(filter:)
          keys = filter[:keys]
          object[:tags].select { |tag| tag[:keys].intersect?(keys) }
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
