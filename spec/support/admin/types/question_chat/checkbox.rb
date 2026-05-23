require "support/admin/types/base/object"
require "support/admin/interfaces/question_chat"
require "support/admin/api_wrappers/chat/checkbox_question_chat"

module SpecSchemas
  module Admin
    module Types
      module QuestionChat
        class Checkbox < Base::Object
          graphql_name "CheckboxQuestionChat"
          implements Interfaces::QuestionChat
          field :id, GraphQL::Types::ID, null: false
          field :value, GraphQL::Types::Boolean, null: false
          def self.proxy_model = ApiWrappers::Chat::CheckboxQuestionChat
        end
      end
    end
  end
end
