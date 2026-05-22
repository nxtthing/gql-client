require "graphql"

module SpecSchemas
  module Types
    # Shared by the admin-back and remote schemas alike.
    class Tag < GraphQL::Schema::Object
      field :value, GraphQL::Types::String, null: false
    end
  end
end
