require "graphql"
require "nxt_gql_client/proxy_resolver"
require "support/admin/interfaces/question_chat"

module SpecSchemas
  module Admin
    module Resolvers
      module Chat
        # admin-back-side resolver for `chat.questions` — analogous to
        # SchedulingTool::Associates::Search. ProxyResolver rebuilds the
        # selection against the chat schema via dynamic_query_params and
        # delegates to the wrapper's `questions`. Named `Questions` so
        # proxy_query_name derives `questions`; proxy_model comes off the
        # result type's interface.
        class Questions < GraphQL::Schema::Resolver
          include NxtGqlClient::ProxyResolver

          type [Interfaces::QuestionChat], null: false
        end
      end
    end
  end
end
