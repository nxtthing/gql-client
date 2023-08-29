require "graphql/client"
require "graphql/client/http"

module NxtGqlClient
  class Api
    attr_reader :url

    def initialize(url, &block)
      @url = url
      @http_client = ::GraphQL::Client::HTTP.new(url, &block)
    end

    def active?
      @url.present?
    end

    def client
      @client ||= begin
        result = ::GraphQL::Client.new(schema:, execute: @http_client)
        result.allow_dynamic_queries = true
        result
      end
    end

    private

    def schema
      @schema ||= ::GraphQL::Client.load_schema(@http_client)
    end
  end
end
