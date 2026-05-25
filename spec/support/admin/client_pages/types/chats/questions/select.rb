require "support/admin/client_pages/types/chats/questions/base"

module SpecSchemas
  module Admin
    module ClientPages
      module Types
        module Chats
          module Questions
            class Select < Base
              graphql_name "SelectQuestionChat"
              field :value, GraphQL::Types::String, null: true
              field :view, GraphQL::Types::String, null: false
            end
          end
        end
      end
    end
  end
end
