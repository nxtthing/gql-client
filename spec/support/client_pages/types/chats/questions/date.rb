require "support/client_pages/types/chats/questions/base"
require "support/client_pages/lib/admin/chats/questions/date"

module SpecSchemas
  module ClientPages
    module Types
      module Chats
        module Questions
          class Date < Base
            graphql_name "DateQuestionChat"
            field :value, GraphQL::Types::ISO8601Date, null: true
            field :view, GraphQL::Types::String, null: false
            def self.proxy_model = ClientPages::Admin::Chats::Questions::Date
          end
        end
      end
    end
  end
end
