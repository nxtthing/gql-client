require "support/client_pages/types/chats/questions/base"
require "support/client_pages/lib/admin/chats/questions/checkbox"

module SpecSchemas
  module ClientPages
    module Types
      module Chats
        module Questions
          class Checkbox < Base
            graphql_name "CheckboxQuestionChat"
            field :value, GraphQL::Types::Boolean, null: false
            def self.proxy_model = ClientPages::Admin::Chats::Questions::Checkbox
          end
        end
      end
    end
  end
end
