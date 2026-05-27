require "support/admin/types/base/object"

module SpecSchemas
  module Admin
    module Types
      class Author < Base::Object
        field :id, GraphQL::Types::ID, null: false
        field :full_name, GraphQL::Types::String, null: false
      end
    end
  end
end
