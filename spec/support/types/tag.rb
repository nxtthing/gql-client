require "graphql"

module SpecSchemas
  module Types
    # Mirrors nxt-scheduling-back's Types::Admin::Tag: a tag row has both a
    # `key` (the filter dimension) and a `value`.
    class Tag < GraphQL::Schema::Object
      field :key, GraphQL::Types::String, null: false
      field :value, GraphQL::Types::String, null: false
    end
  end
end
