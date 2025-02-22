require "nxt_gql_client/invalid_response"

module NxtGqlClient
  module ProxyResolver
    extend ActiveSupport::Concern

    def resolve(**args)
      resolve_proxy(**args)
    end

    protected

    def proxy_model
      Model.field_type(self.class).proxy_model
    end

    def resolve_proxy(**)
      proxy_model.public_send(
        proxy_query_name,
        **Model.dynamic_query_params(
          node: to_node,
          result_class: self.class,
          context:
        ),
        variables: proxy_arguments,
        context: proxy_context
      )
    rescue InvalidResponse => exc
      handle_invalid_response_error(exc)
    end

    class_methods do
      def proxy_arguments(value)
        return if value.nil?
        return value unless argument_class.include?(NxtGqlClient::ProxyArgument)

        arguments.values.
          select(&:proxy).
          select { |arg_klass| value.key?(arg_klass.keyword) }.
          to_h { |arg_klass| [arg_klass.proxy_name, arg_klass.proxy_value(value[arg_klass.keyword])] }
      end
    end

    def proxy_arguments
      self.class.proxy_arguments(arguments)
    end

    def proxy_context
      GraphQL::Query::NullContext.instance
    end

    def proxy_query_name
      self.class.name.demodulize.underscore
    end

    def handle_invalid_response_error(exc)
      raise exc
    end

    private

    def to_node
      object_name = object.field.name
      field_name = field.name
      context.query.document.definitions.each do |definition|
        definition.selections.each do |selection|
          selection_object = selection if selection.name == object_name
          selection_object ||= selection.
            children.
            find { |child| child.name == object_name }
          if selection_object
            node = selection_object.
              children.
              find { |child| child.name == field_name }
            return node if node
          end
        end
      end

      raise "no definition for #{object_name}.#{field_name} resolver"
    end
  end
end
