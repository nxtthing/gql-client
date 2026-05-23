require "support/chat/types/base/object"
require "support/chat/interfaces/question_chat"

module SpecSchemas
  module Chat
    module Types
      module QuestionChat
        class Date < Base::Object
          graphql_name "DateQuestionChat"
          implements Interfaces::QuestionChat
          field :id, GraphQL::Types::ID, null: false
          field :value, GraphQL::Types::ISO8601Date, null: true
          field :view, GraphQL::Types::String, null: false
        end
      end
    end
  end
end
