require "nxt_gql_client/model"
require "support/admin/api_wrappers/scheduling_tool/api"

module SpecSchemas
  module Admin
    module ApiWrappers
      module SchedulingTool
        # Wrapper model the ProxyResolver delegates `search` to — the
        # spec-side counterpart of admin-back's
        # ApiWrappers::SchedulingTool::Associate. `query :search` declares
        # the entry point; the proxied selection node_to_gql rebuilds is
        # spliced in where `response` interpolates.
        #
        # Only `id` needs an explicit attribute reader: the proxy_alias
        # fields and the frontend-aliased tenancy_skills are read off
        # `object.object` by the admin-side type's resolvers, for which
        # Model's `delegate :[]` is enough.
        class Associate
          include NxtGqlClient::Model

          # node_to_gql pins preserved_aliases under `proxy_model.typename`;
          # it must be the remote schema's name (`Associate`).
          typename "Associate"

          attributes :id

          def self.api = Api.instance

          query :search do |response|
            <<~GQL
              query { associate { search #{response} } }
            GQL
          end
        end
      end
    end
  end
end
