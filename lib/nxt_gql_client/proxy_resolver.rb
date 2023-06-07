require "nxt_gql_client/invalid_response"

module NxtGqlClient
  module ProxyResolver
    def resolve(**params)
      query_name = self.class.name.demodulize.downcase
      self.class.type.unwrap.proxy_model.send(query_name, resolver: self, **params)
    rescue NxtSchedulingGql::InvalidResponse => exc
      handle_invalid_response_error(exc)
    end

    protected

    def handle_invalid_response_error(exc)
      raise exc
    end
  end
end
