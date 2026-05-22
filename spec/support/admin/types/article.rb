require "graphql"
require "support/proxy_field_class"
require "support/admin/types/author"

module SpecSchemas
  module Admin
    module Types
      class Article < GraphQL::Schema::Object
        field_class SpecSchemas.proxy_field_class
        field :id, GraphQL::Types::ID, null: false
        field :title, GraphQL::Types::String, null: false
        # proxy_alias with no `:` — renames the field to the remote name
        # without aliasing, so node_to_gql emits `writer` instead of `author`.
        field :author, Author, null: false, proxy_alias: "writer" do
          argument :revision, GraphQL::Types::Int, required: false
        end
      end
    end
  end
end
