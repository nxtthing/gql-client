require "graphql"
require "nxt_gql_client/proxy_field"

module SpecSchemas
  module Admin
    module Types
      module Base
        # Counterpart of admin-back's Types::Base::Field: a custom field
        # class that mixes in NxtGqlClient::ProxyField, so every type
        # inheriting Base::Object can use `proxy_alias:` / `proxy:` etc.
        class Field < GraphQL::Schema::Field
          include NxtGqlClient::ProxyField
        end
      end
    end
  end
end
