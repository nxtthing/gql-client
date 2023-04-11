module NxtGqlClient
  class Api
    def initialize(url)
      @url = url
    end

    def client
      @client ||= begin
                    result = ::GraphQL::Api.new(schema: schema, execute: http_client)
                    result.allow_dynamic_queries = true
                    result
                  end
    end

    private

    def http_client
      @http_client ||= ::GraphQL::Api::HTTP.new(url)
    end

    def schema
      @schema ||= ::GraphQL::Api.load_schema(http_client)
    end
  end
end
