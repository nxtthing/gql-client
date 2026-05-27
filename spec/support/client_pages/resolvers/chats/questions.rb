require "graphql"
require "nxt_gql_client/proxy_resolver"
require "support/client_pages/interfaces/chats/question"
require "support/client_pages/lib/admin/chat"

module SpecSchemas
  module ClientPages
    module Resolvers
      module Chats
        # Mirrors nxt-client-pages-back's Resolvers::Chats::* leaves —
        # ProxyResolver rebuilds the selection against the admin-back
        # ClientPages schema via dynamic_query_params and delegates to the
        # wrapper's `questions`. Named `Questions` so proxy_query_name
        # derives `questions`. proxy_model is the Chat wrapper (it owns
        # `query :questions`); the polymorphic interface returns sit
        # elsewhere — admin/types and their per-implementer proxy_model.
        class Questions < GraphQL::Schema::Resolver
          include NxtGqlClient::ProxyResolver

          type [Interfaces::Chats::Question], null: false

          protected

          def proxy_model = ClientPages::Admin::Chat
        end
      end
    end
  end
end
