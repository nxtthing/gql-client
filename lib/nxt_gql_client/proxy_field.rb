module NxtGqlClient
  module ProxyField
    extend ActiveSupport::Concern

    included do
      attr_reader :proxy_attrs, :proxy_children, :proxy, :proxy_alias

      class_eval do
        # rubocop:disable Metrics/ParameterLists
        def initialize(*args, proxy: true, proxy_attrs: true, proxy_children: true, proxy_alias: nil, **kwargs, &block)
          # rubocop:enable Metrics/ParameterLists
          super(*args, **kwargs, &block)
          @proxy_attrs = proxy_attrs
          @proxy = proxy
          @proxy_children = proxy_children
          @proxy_alias = proxy_alias
        end
      end

      def proxy_name
        @proxy_alias || (method_sym == original_name ? name : method_str)
      end

      # Response key the remote will return data under when @proxy_alias
      # injects a `name: realField(...)` selection. nil when proxy_alias has
      # no `:`-prefix (i.e. it isn't aliasing anything).
      def proxy_alias_key
        return unless @proxy_alias

        match = @proxy_alias.to_s.match(/\A\s*([A-Za-z_][A-Za-z0-9_]*)\s*:/)
        match && match[1]
      end
    end
  end
end
