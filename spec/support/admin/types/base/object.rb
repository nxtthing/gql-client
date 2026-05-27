require "graphql"
require "support/admin/types/base/field"

module SpecSchemas
  module Admin
    module Types
      module Base
        # Counterpart of admin-back's Types::Base::Object: all admin object
        # types inherit this so they pick up the ProxyField-enabled field
        # class without each file repeating `field_class ...`.
        class Object < GraphQL::Schema::Object
          field_class Field
        end
      end
    end
  end
end
