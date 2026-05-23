require "graphql"
require "support/chat/interfaces/question_chat"
require "support/chat/data/question_chat/store"

module SpecSchemas
  module Chat
    module Resolvers
      # Resolves `chat.questions` — serves the seeded polymorphic question
      # list out of the chat-service store.
      class Questions < GraphQL::Schema::Resolver
        type [Interfaces::QuestionChat], null: false

        def resolve
          Data::QuestionChat::Store.questions
        end
      end
    end
  end
end
