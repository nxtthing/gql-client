module NxtGqlClient
  module ProxyArgument
    extend ActiveSupport::Concern

    included do
      attr_reader :proxy

      class_eval do
        def initialize(*args, proxy: true, proxy_alias: nil, **kwargs, &block)
          super(*args, **kwargs, &block)
          @proxy = proxy
          @proxy_alias = proxy_alias
        end
      end

      def proxy_name
        @proxy_alias || name
      end

      def proxy_value(value)
        return if value.nil?

        case type.kind.name
          when "INPUT_OBJECT"
            type.arguments.
              select { |_, v| v.respond_to?(:proxy) && v.proxy }.
              to_h do |name, argument_klass|
              key = name.underscore.to_sym
              [argument_klass.proxy_name, argument_klass.proxy_value(value[key])]
            end
          when "ENUM", "SCALAR"
            format_value(value)
          else
            raise TypeError, "unexpected #{type.class} (#{type.inspect})"
        end
      end

      def format_value(value)
        case value
          when ::Time, ::Date
            value.iso8601
          else
            value
        end
      end
    end
  end
end
