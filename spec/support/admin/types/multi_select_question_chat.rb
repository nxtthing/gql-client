require "graphql"
require "support/proxy_field_class"
require "support/proxy_model_stub"
require "support/admin/types/question_chat"

module SpecSchemas
  module Admin
    module Types
      class MultiSelectQuestionChat < GraphQL::Schema::Object
        implements QuestionChat
        field_class SpecSchemas.proxy_field_class
        field :id, GraphQL::Types::ID, null: false
        field :value, [GraphQL::Types::String], null: false
        def self.proxy_model = ProxyModelStub.new("MultiSelectQuestionChat")
      end
    end
  end
end
