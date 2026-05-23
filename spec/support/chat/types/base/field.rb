require "graphql"

module SpecSchemas
  module Chat
    module Types
      module Base
        # Plain field — the chat service has nothing to proxy, it *is* the
        # remote. No ProxyField mix-in.
        class Field < GraphQL::Schema::Field
        end
      end
    end
  end
end
