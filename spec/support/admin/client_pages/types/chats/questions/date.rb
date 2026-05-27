require "support/admin/client_pages/types/chats/questions/base"

module SpecSchemas
  module Admin
    module ClientPages
      module Types
        module Chats
          module Questions
            class Date < Base
              graphql_name "DateQuestionChat"
              field :value, GraphQL::Types::ISO8601Date, null: true
              field :view, GraphQL::Types::String, null: false
            end
          end
        end
      end
    end
  end
end
