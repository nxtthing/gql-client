require "graphql"
require "support/proxy_model_stub"

module SpecSchemas
  module Admin
    module Types
      module QuestionChat
        include GraphQL::Schema::Interface

        graphql_name "QuestionChat"
        description "Polymorphic interface — exercises node_to_gql's handling of interface selections."
        field :id, GraphQL::Types::ID, null: false

        definition_methods do
          def proxy_model = ProxyModelStub.new("QuestionChat")
        end
      end
    end
  end
end
