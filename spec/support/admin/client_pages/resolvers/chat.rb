require "graphql"
require "support/admin/client_pages/types/base/object"
require "support/admin/client_pages/interfaces/chats/question"
require "support/admin/client_pages/data/chats/store"

module SpecSchemas
  module Admin
    module ClientPages
      module Resolvers
        # Mirrors nxt-admin-back's ClientPages::Resolvers::Chat — grouping
        # resolver exposing nested actions admin-back serves to
        # client-pages-back. Prod has conversation/event under here too;
        # the spec models just `questions` (the polymorphic surface).
        class Chat < GraphQL::Schema::Resolver
          class Actions < Types::Base::Object
            graphql_name "ChatActions"
            field :questions, [Interfaces::Chats::Question], null: false

            def questions = Data::Chats::Store.questions
          end

          type Actions, null: false

          def resolve = self
        end
      end
    end
  end
end
