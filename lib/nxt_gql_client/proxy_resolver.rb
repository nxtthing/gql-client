require "nxt_gql_client/invalid_response"

module NxtGqlClient
  module ProxyResolver
    def resolve(proxy_model: nil, **params)
      query_name = self.class.name.demodulize.underscore
      proxy_model ||= Model.field_type(self.class).proxy_model
      proxy_model.send(query_name, resolver: self, **params)
    rescue InvalidResponse => exc
      handle_invalid_response_error(exc)
    end

    protected

    def handle_invalid_response_error(exc)
      raise exc
    end
  end
end
