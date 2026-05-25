require "graphql/client"
require "nxt_gql_client/api"
require "support/local_schema_execute"
require "support/scheduling/schema"

module SpecSchemas
  module Admin
    # admin-back-side API wrappers — the spec counterpart of admin-back's
    # lib/api_wrappers. The scheduling-tool service itself (schema, types,
    # data) lives under SpecSchemas::Scheduling.
    module ApiWrappers
      module SchedulingTool
        # A NxtGqlClient::Api wired to the in-process scheduling-tool schema
        # instead of a real endpoint. Production builds its GraphQL::Client
        # by loading the schema over HTTP; here we hand it the local schema
        # and a local-execute adapter, so the wrapper runs end to end
        # without a network.
        module Api
          module_function

          def instance
            @instance ||= begin
              api = NxtGqlClient::Api.allocate
              api.instance_variable_set(:@url, "local://scheduling-tool")
              schema = SpecSchemas::Scheduling::Schema
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
end
