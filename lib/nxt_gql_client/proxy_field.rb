module NxtGqlClient
  module ProxyField
    extend ActiveSupport::Concern

    included do
      class_eval do
        def initialize(*args, proxy_ignore_attrs: false, **kwargs, &block)
          super(*args, **kwargs, &block)
          @proxy_ignore_attrs = proxy_ignore_attrs
        end
      end
    end
  end
end
