module NxtGqlClient
  module ProxyInputObject
    extend ActiveSupport::Concern

    class_methods do
      def proxy_value(value)
        return if value.nil?

        arguments.
          select { |_, v| v.respond_to?(:proxy) && v.proxy }.
          select { |name, _| value.key?(name.underscore.to_sym) }.
          to_h { |name, klass| [klass.proxy_name, klass.proxy_value(value[name.underscore.to_sym])] }
      end
    end

    def proxy_value
      self.class.proxy_value(self)
    end
  end
end
