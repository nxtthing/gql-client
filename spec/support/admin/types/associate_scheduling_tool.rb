require "graphql"
require "support/proxy_field_class"
require "support/proxy_model_stub"
require "support/types/tag"
require "support/admin/types/tag_value"

module SpecSchemas
  module Admin
    module Types
      # rubocop:disable Layout/LineLength
      class AssociateSchedulingTool < GraphQL::Schema::Object
        field_class SpecSchemas.proxy_field_class

        description <<~DESC
          Client-facing (admin-back) shape — what node_to_gql rebuilds from.
          Its graphql_name is deliberately different from proxy_model.typename
          (`Associate`); that mismatch is the prod reality preserved_aliases
          must survive.
        DESC

        field :id, GraphQL::Types::ID, null: false

        # `primary_functions` is snake_case in the proxy_alias on purpose —
        # that's what admin-back's tags_field emits via gql(alias_name:). The
        # whole string then goes through camelize(:lower), so it reaches the
        # remote as `primaryFunctions:`; the pin must match that camelCased form.
        field :trainings, [TagValue], null: false,
                                      proxy_alias: 'trainings: tags(filter: { keys: ["training"] }) { value }'
        field :primary_functions, [TagValue], null: false,
                                              proxy_alias: 'primary_functions: tags(filter: { keys: ["primaryFunction"] }) { value }'
        field :types, [TagValue], null: false,
                                  proxy_alias: 'types: tags(filter: { keys: ["type"] }) { value }'

        # data lands in `object.object[:trainings]` as `[{value: "X"}, ...]`
        # (the tagged remote response); flatten to the enum's bare values.
        %i[trainings primary_functions types].each do |name|
          define_method(name) { object.object[name].map { |row| row[:value] } }
        end

        field :tenancy_skills, [SpecSchemas::Types::Tag], null: false, extras: [:ast_node],
                                                          description: "Non-proxy field the frontend may alias with different args; each alias resolves against its own response bucket." do
          argument :tenancy_ids, [GraphQL::Types::String], required: false
        end

        def tenancy_skills(ast_node:, tenancy_ids: nil) # rubocop:disable Lint/UnusedMethodArgument
          # transform_response collapses single-use frontend aliases back to the
          # canonical schema name and only preserves them as distinct keys when
          # there's a real collision (alias count >= 2). Read the alias first,
          # fall back to canonical.
          alias_key     = ast_node.alias&.underscore&.to_sym
          canonical_key = ast_node.name.underscore.to_sym
          object.object[alias_key] || object.object[canonical_key]
        end

        def self.proxy_model = ProxyModelStub.new("Associate")
      end
      # rubocop:enable Layout/LineLength
    end
  end
end
