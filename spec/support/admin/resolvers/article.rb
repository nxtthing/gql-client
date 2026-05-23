require "graphql"
require "support/admin/types/article"
require "support/admin/data/article/store"

module SpecSchemas
  module Admin
    module Resolvers
      # Resolves the `article` Query-root field, serving the seeded article
      # from the Article store.
      class Article < GraphQL::Schema::Resolver
        type Types::Article, null: false

        def resolve
          Data::Article::Store.article
        end
      end
    end
  end
end
