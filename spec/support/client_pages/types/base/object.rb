require "graphql"
require "nxt_gql_client/proxy_field"

module SpecSchemas
  module ClientPages
    module Types
      module Base
        # Mirrors nxt-client-pages-back's Types::Base::Object — uses a
        # custom field class with ProxyField mixed in, so client-pages-side
        # types can declare proxy_alias.
        class Field < GraphQL::Schema::Field
          include NxtGqlClient::ProxyField
        end

        class Object < GraphQL::Schema::Object
          field_class Field
        end
      end
    end
  end
end
