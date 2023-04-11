require "graphql/client"
require "graphql/client/http"

require "nxt_gql_client/api"
require "nxt_gql_client/query"
require "nxt_gql_client/invalid_response"

module NxtGqlClient
  def query(name, gql, response_path = nil)
    define_singleton_method name do |**args|
      var_name = "@#{name}"
      definition = if instance_variable_defined?(var_name)
                     instance_variable_get(var_name)
                   else
                     instance_variable_set(var_name, parse_query(query: gql, response_path:))
                   end
      definition.call(**args)
    end
  end

  def api_url(val = nil)
    if val
      api = Api.new(val)
      define_method :api do
        api
      end
    else
      api.url
    end

  end

  private

  def parse_query(query:, response_path:)
    definition = api.client.parse(query)
    Query.new(query_definition: definition, api:, response_path:)
  end
end
