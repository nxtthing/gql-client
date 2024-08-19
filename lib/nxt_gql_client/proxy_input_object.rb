module NxtGqlClient
  module ProxyInputObject
    extend ActiveSupport::Concern

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
      self.class.proxy_arguments(self)
    end
  end
end
