module NxtGqlClient
  module ProxyArgument
    extend ActiveSupport::Concern

    included do
      attr_reader :proxy, :proxy_alias

      class_eval do
        def initialize(*args, proxy: true, proxy_alias: nil, **kwargs, &block)
          super(*args, **kwargs, &block)
          @proxy = proxy
          @proxy_alias = proxy_alias
        end
      end

      def proxy_name
        @proxy_alias || keyword
      end

      def proxy_value(value, type: self.type)
        return value if prepare.present?
        return if value.nil?

        case type.kind.name
          when "INPUT_OBJECT"
            type.proxy_value(value)
          when "NON_NULL"
            proxy_value(value, type: type.of_type)
          when "LIST"
            value.map { |row| proxy_value(row, type: type.of_type) }
          when "ENUM"
            value
          when "SCALAR"
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
