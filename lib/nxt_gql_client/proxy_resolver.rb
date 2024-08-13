require "nxt_gql_client/invalid_response"

module NxtGqlClient
  module ProxyResolver
    def resolve(**args)
      resolve_proxy(**args)
    end

    protected

    def proxy_model
      Model.field_type(self.class).proxy_model
    end

    def resolve_proxy(**original_args)
      proxy_model.send(proxy_query_name, resolver: self, **proxy_args(original_args), context: proxy_context(context))
    rescue InvalidResponse => exc
      handle_invalid_response_error(exc)
    end

    def proxy_args(original_args)
      @arguments_by_keyword.
        select { |_, argument| argument.proxy }.
        to_h { |key, argument| [argument.proxy_name, argument.proxy_value(original_args[key])] }
    end

    def proxy_context(_context)
      GraphQL::Query::NullContext.instance
    end

    def proxy_query_name
      self.class.name.demodulize.underscore
    end

    def handle_invalid_response_error(exc)
      raise exc
    end
  end
end
