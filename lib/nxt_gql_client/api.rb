require "graphql/client"
require "graphql/client/http"

module NxtGqlClient
  class Api
    attr_reader :url

    def initialize(url)
      @url = url
    end

    def client
      @client ||= begin
        result = ::GraphQL::Client.new(schema: schema, execute: http_client)
        result.allow_dynamic_queries = true
        result
      end
    end

    private

    def http_client
      @http_client ||= ::GraphQL::Client::HTTP.new(url)
    end

    def schema
      @schema ||= ::GraphQL::Client.load_schema(http_client)
    end
  end
end
