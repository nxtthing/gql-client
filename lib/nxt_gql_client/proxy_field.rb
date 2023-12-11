module NxtGqlClient
  module ProxyField
    extend ActiveSupport::Concern

    included do
      attr_reader :proxy_attrs, :proxy_children

      class_eval do
        def initialize(*args, proxy_attrs: true, proxy_children: true, proxy_alias: nil, **kwargs, &block)
          super(*args, **kwargs, &block)
          @proxy_attrs = proxy_attrs
          @proxy_children = proxy_children
          @proxy_alias = proxy_alias
        end
      end

      def proxy_name
        @proxy_alias || (method_sym == original_name ? name : method_str)
      end
    end
  end
end
