require "graphql"
require "support/admin/types/base/object"
require "support/admin/resolvers/chat/questions"

module SpecSchemas
  module Admin
    module Resolvers
      module Chat
        # Counterpart of Resolvers::SchedulingTool::Self for the chat
        # service. Returns itself and exposes `questions` underneath; the
        # real proxy work happens in the Questions resolver.
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
end
