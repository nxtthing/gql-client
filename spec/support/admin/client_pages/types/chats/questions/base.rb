require "support/admin/client_pages/types/base/object"
require "support/admin/client_pages/interfaces/chats/question"

module SpecSchemas
  module Admin
    module ClientPages
      module Types
        module Chats
          module Questions
            # Mirrors nxt-admin-back's ClientPages::Types::Chats::Questions::Base.
            #
            # Each implementer doubles as its own proxy_model: node_to_gql
            # reads `.typename` off it for inline-fragment rebuilds. Prod
            # admin-back types don't need this (chat is DB-backed there),
            # but the spec exercises unit tests that go through node_to_gql
            # against this surface, so the implementers stand in.
            class Base < ClientPages::Types::Base::Object
              implements ClientPages::Interfaces::Chats::Question

              def self.proxy_model = self
              def self.typename = graphql_name
            end
          end
        end
      end
    end
  end
end
