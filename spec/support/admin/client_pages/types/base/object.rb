require "support/admin/types/base/object"

module SpecSchemas
  module Admin
    module ClientPages
      module Types
        # Mirrors nxt-admin-back's ClientPages::Types::Object — admin types
        # exposed via the ClientPages schema inherit from the same base as
        # the main admin types (Admin::Types::Base::Object), so they pick
        # up ProxyField.
        module Base
          class Object < SpecSchemas::Admin::Types::Base::Object
          end
        end
      end
    end
  end
end
