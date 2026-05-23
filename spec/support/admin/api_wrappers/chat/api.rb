require "graphql/client"
require "nxt_gql_client/api"
require "support/local_schema_execute"
require "support/chat/schema"

module SpecSchemas
  module Admin
    module ApiWrappers
      module Chat
        # NxtGqlClient::Api wired to the in-process chat schema instead of a
        # real endpoint. Mirrors ApiWrappers::SchedulingTool::Api.
        module Api
          module_function

          def instance
            @instance ||= begin
              api = NxtGqlClient::Api.allocate
              api.instance_variable_set(:@url, "local://chat")
              schema = SpecSchemas::Chat::Schema
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
