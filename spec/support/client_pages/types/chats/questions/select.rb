require "support/client_pages/types/chats/questions/base"
require "support/client_pages/lib/admin/chats/questions/select"

module SpecSchemas
  module ClientPages
    module Types
      module Chats
        module Questions
          class Select < Base
            graphql_name "SelectQuestionChat"
            field :value, GraphQL::Types::String, null: true
            field :view, GraphQL::Types::String, null: false
            def self.proxy_model = ClientPages::Admin::Chats::Questions::Select
          end
        end
      end
    end
  end
end
