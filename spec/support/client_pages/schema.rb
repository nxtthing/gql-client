require "graphql"
require "support/client_pages/types/base/object"
require "support/client_pages/resolvers/chat"

module SpecSchemas
  module ClientPages
    # Mirrors nxt-client-pages-back's Schemas::Admin.
    class Query < Types::Base::Object
      field :chat, resolver: Resolvers::Chat
    end

    class Schema < GraphQL::Schema
      query Query

      def self.resolve_type(abstract_type, object, context)
        abstract_type.resolve_type(object, context)
      end
    end
  end
end
