require "graphql"
require "support/admin/client_pages/resolvers/chat"

module SpecSchemas
  module Admin
    module ClientPages
      # Mirrors nxt-admin-back's ClientPages::Types::Query — the entry
      # point exposed to client-pages-back via /client_pages/graphql.
      class Query < Types::Base::Object
        field :chat, resolver: Resolvers::Chat
      end

      # Mirrors nxt-admin-back's ClientPages::Schema. Separate from the
      # main Admin::Schema: admin-back actually runs two schemas, one for
      # internal use and one served to client-pages-back, so the spec does
      # the same.
      class Schema < GraphQL::Schema
        query Query

        # Polymorphic resolution lives on the interface (see
        # interfaces/chats/question.rb), so this Schema's resolve_type
        # delegates there.
        def self.resolve_type(abstract_type, object, context)
          abstract_type.resolve_type(object, context)
        end
      end
    end
  end
end
