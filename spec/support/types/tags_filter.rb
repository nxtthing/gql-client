require "graphql"

module SpecSchemas
  module Types
    # The filter argument the remote `tags(...)` field takes.
    class TagsFilter < GraphQL::Schema::InputObject
      argument :keys, [GraphQL::Types::String], required: true
    end
  end
end
