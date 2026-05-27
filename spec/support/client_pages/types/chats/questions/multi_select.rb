require "support/client_pages/types/chats/questions/base"
require "support/client_pages/lib/admin/chats/questions/multi_select"

module SpecSchemas
  module ClientPages
    module Types
      module Chats
        module Questions
          class MultiSelect < Base
            graphql_name "MultiSelectQuestionChat"
            field :value, [GraphQL::Types::String], null: false
            def self.proxy_model = ClientPages::Admin::Chats::Questions::MultiSelect
          end
        end
      end
    end
  end
end
