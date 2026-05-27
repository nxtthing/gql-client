require "graphql"

module SpecSchemas
  module Scheduling
    module Types
      # Mirrors nxt-scheduling-back's Inputs::Tags::Filters::ByKeys — the
      # filter argument the `tags(filter:)` field takes.
      class TagsFilter < GraphQL::Schema::InputObject
        argument :keys, [GraphQL::Types::String], required: true
      end
    end
  end
end
