require "support/admin/types/base/object"
require "support/admin/interfaces/question_chat"
require "support/admin/api_wrappers/chat/date_question_chat"

module SpecSchemas
  module Admin
    module Types
      module QuestionChat
        class Date < Base::Object
          graphql_name "DateQuestionChat"
          implements Interfaces::QuestionChat
          field :id, GraphQL::Types::ID, null: false
          field :value, GraphQL::Types::ISO8601Date, null: true
          field :view, GraphQL::Types::String, null: false
          def self.proxy_model = ApiWrappers::Chat::DateQuestionChat
        end
      end
    end
  end
end
