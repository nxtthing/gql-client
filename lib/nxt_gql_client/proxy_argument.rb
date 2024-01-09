module NxtGqlClient
  module ProxyInputObject
    extend ActiveSupport::Concern

    included do

      class_eval do
        def initialize(*args, proxy_alias: nil, **kwargs, &block)
          super(*args, **kwargs, &block)
          @proxy_alias = proxy_alias
        end
      end

      def proxy_name
        @proxy_alias || name
      end
    end
  end
end
