require "support/chat/types/base/object"
require "support/chat/interfaces/question_chat"

module SpecSchemas
  module Chat
    module Types
      module QuestionChat
        class MultiSelect < Base::Object
          graphql_name "MultiSelectQuestionChat"
          implements Interfaces::QuestionChat
          field :id, GraphQL::Types::ID, null: false
          field :value, [GraphQL::Types::String], null: false
        end
      end
    end
  end
end
