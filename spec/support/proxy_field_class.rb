require "graphql"
require "nxt_gql_client/proxy_field"

# Shared field class used across the admin-back-side spec schema. Mixing in
# ProxyField is what makes `proxy_alias:`/`proxy:` field options available —
# the spec schemas exercise that path the same way the host app does.
module SpecSchemas
  def self.proxy_field_class
    @proxy_field_class ||= Class.new(GraphQL::Schema::Field) do
      include NxtGqlClient::ProxyField
    end
  end
end
