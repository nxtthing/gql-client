require "support/admin/client_pages/types/chats/questions/base"

module SpecSchemas
  module Admin
    module ClientPages
      module Types
        module Chats
          module Questions
            class Checkbox < Base
              graphql_name "CheckboxQuestionChat"
              field :value, GraphQL::Types::Boolean, null: false
            end
          end
        end
      end
    end
  end
end
