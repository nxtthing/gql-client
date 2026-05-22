require "graphql"
require "support/proxy_field_class"

module SpecSchemas
  module Admin
    module Types
      class Author < GraphQL::Schema::Object
        field_class SpecSchemas.proxy_field_class
        field :id, GraphQL::Types::ID, null: false
        field :full_name, GraphQL::Types::String, null: false
      end
    end
  end
end
