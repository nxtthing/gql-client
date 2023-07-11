module NxtGqlClient
  module ProxyField
    extend ActiveSupport::Concern

    included do
      class_eval do
        def initialize(*args, ignore_proxy_attrs: false, **kwargs, &block)
          super(*args, **kwargs, &block)
          @ignore_proxy_attrs = ignore_proxy_attrs
        end
      end
    end

    def proxy_attrs?
      !@ignore_proxy_attrs
    end
  end
end
