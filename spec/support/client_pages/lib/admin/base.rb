require "graphql/client"
require "nxt_gql_client/api"
require "nxt_gql_client/model"
require "support/local_schema_execute"
require "support/admin/client_pages/schema"

module SpecSchemas
  module ClientPages
    # Mirrors nxt-client-pages-back's lib/admin/. Houses ApiWrappers that
    # call out to admin-back's ClientPages schema (in prod via
    # ENV["PORTAL_GQL_URL"]; here via LocalSchemaExecute).
    module Admin
      class Base
        include NxtGqlClient::Model

        # NxtGqlClient::Model expects an api object whose .client returns a
        # GraphQL::Client. Build one talking to the in-process Admin
        # ClientPages schema instead of HTTP.
        def self.api
          @api ||= begin
            schema = SpecSchemas::Admin::ClientPages::Schema
            api = NxtGqlClient::Api.allocate
            api.instance_variable_set(:@url, "local://admin-client-pages")
            client = GraphQL::Client.new(
              schema: schema,
              execute: LocalSchemaExecute.new(schema)
            )
            client.allow_dynamic_queries = true
            api.instance_variable_set(:@client, client)
            api
          end
        end
      end
    end
  end
end
