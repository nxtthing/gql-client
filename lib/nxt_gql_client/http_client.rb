require "graphql/client/http"

module NxtGqlClient
  class HttpClient < ::GraphQL::Client::HTTP
    def connection
      super.tap do |client|
        client.read_timeout = 180
      end
    end
  end
end
