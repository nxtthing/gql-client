require "support/admin/types/base/object"
require "support/admin/interfaces/question_chat"
require "support/admin/api_wrappers/chat/select_question_chat"

module SpecSchemas
  module Admin
    module Types
      module QuestionChat
        class Select < Base::Object
          graphql_name "SelectQuestionChat"
          implements Interfaces::QuestionChat
          field :id, GraphQL::Types::ID, null: false
          field :value, GraphQL::Types::String, null: true
          field :view, GraphQL::Types::String, null: false
          def self.proxy_model = ApiWrappers::Chat::SelectQuestionChat
        end
      end
    end
  end
end
