require "graphql"
require "support/chat/resolvers/self"

module SpecSchemas
  module Chat
    class Query < GraphQL::Schema::Object
      field :chat, resolver: Resolvers::Self
    end

    # Standalone, fully executable chat-service schema, mirroring the
    # scheduling-tool one. The admin wrapper talks to it via GraphQL::Client
    # + LocalSchemaExecute. Owns its polymorphic QuestionChat tree
    # (interface + 4 implementers + resolve_type) so the e2e spec exercises
    # polymorphic round-trip aliases against a real GraphQL server.
    class Schema < GraphQL::Schema
      query Query
    end
  end
end
