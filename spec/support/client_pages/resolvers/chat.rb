require "graphql"
require "support/client_pages/types/base/object"
require "support/client_pages/resolvers/chats/questions"

module SpecSchemas
  module ClientPages
    module Resolvers
      # Mirrors nxt-client-pages-back's Resolvers::Chat — grouping
      # resolver exposing nested actions. The real proxy work happens in
      # Chats::Questions.
      class Chat < GraphQL::Schema::Resolver
        class Objects < Types::Base::Object
          graphql_name "ChatActions"
          field :questions, resolver: Chats::Questions
        end

        type Objects, null: false

        def resolve = self
      end
    end
  end
end
