require "nxt_gql_client/invalid_response"

module NxtGqlClient
  module ProxyResolver
    def resolve(**params)
      resolve_proxy(proxy_model: Model.field_type(self.class).proxy_model, **params)
    end

    protected

    def resolve_proxy(proxy_model:, **params)
      query_name = self.class.name.demodulize.underscore
      proxy_model.send(query_name, resolver: self, **params)
    rescue InvalidResponse => exc
      handle_invalid_response_error(exc)
    end

    def handle_invalid_response_error(exc)
      raise exc
    end
  end
end
