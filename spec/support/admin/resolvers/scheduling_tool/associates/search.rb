require "graphql"
require "nxt_gql_client/proxy_resolver"
require "support/admin/types/associate_scheduling_tool"

module SpecSchemas
  module Admin
    module Resolvers
      module SchedulingTool
        module Associates
          # admin-back-side resolver for `associate.search` — counterpart of
          # Resolvers::SchedulingTool::Associates::Search. Including
          # ProxyResolver is the whole point: it rebuilds the selection
          # against the scheduling-tool schema via dynamic_query_params and
          # delegates to the wrapper's `search`. Named `Search` so
          # ProxyResolver's `proxy_query_name` derives `search` itself;
          # proxy_model comes off the result type. Nothing is overridden.
          class Search < GraphQL::Schema::Resolver
            include NxtGqlClient::ProxyResolver

            type Admin::Types::AssociateSchedulingTool, null: false
          end
        end
      end
    end
  end
end
