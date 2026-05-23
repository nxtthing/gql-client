require "graphql"
require "support/chat/types/base/object"
require "support/chat/resolvers/questions"

module SpecSchemas
  module Chat
    module Resolvers
      # Grouping resolver — returns itself and exposes the chat-service
      # actions underneath. Mirrors the SchedulingTool::Self pattern.
      class Self < GraphQL::Schema::Resolver
        class Objects < Types::Base::Object
          graphql_name "ChatActions"
          field :questions, resolver: Questions
        end

        type Objects, null: false

        def resolve = self
      end
    end
  end
end
