require "support/admin/client_pages/types/chats/questions/base"

module SpecSchemas
  module Admin
    module ClientPages
      module Types
        module Chats
          module Questions
            class MultiSelect < Base
              graphql_name "MultiSelectQuestionChat"
              field :value, [GraphQL::Types::String], null: false
            end
          end
        end
      end
    end
  end
end
