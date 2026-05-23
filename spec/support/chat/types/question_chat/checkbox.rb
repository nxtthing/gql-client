require "support/chat/types/base/object"
require "support/chat/interfaces/question_chat"

module SpecSchemas
  module Chat
    module Types
      module QuestionChat
        class Checkbox < Base::Object
          graphql_name "CheckboxQuestionChat"
          implements Interfaces::QuestionChat
          field :id, GraphQL::Types::ID, null: false
          field :value, GraphQL::Types::Boolean, null: false
        end
      end
    end
  end
end
