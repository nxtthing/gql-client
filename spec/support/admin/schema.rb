require "graphql"
require "support/admin/resolvers/scheduling_tool/self"
require "support/admin/resolvers/scheduling_tool/remote_associate"
require "support/admin/resolvers/chat/self"
require "support/admin/resolvers/article"

module SpecSchemas
  module Admin
    # Query root, shaped like admin-back's: each remote-service tree hangs
    # off its own `*` resolver, mirroring the prod chain
    # Query -> schedulingTool -> associate -> search
    # Query -> chat -> questions
    # `article` is an unrelated subtree kept top-level for the node_to_gql
    # unit specs; `remoteAssociate` exposes the remote-shaped type for the
    # transform_response specs. Every field is fully executable.
    class Query < GraphQL::Schema::Object
      field :scheduling_tool, resolver: Resolvers::SchedulingTool::Self
      field :remote_associate, resolver: Resolvers::SchedulingTool::RemoteAssociate
      field :chat, resolver: Resolvers::Chat::Self
      field :article, resolver: Resolvers::Article
    end

    # The admin-back-side spec schema — one schema, prod-shaped. The
    # end-to-end specs run queries through the real ProxyResolver chain;
    # the node_to_gql / transform_response unit specs reach into it for
    # types and parse selections against it. The QuestionChat implementers
    # reach the schema as that interface's orphan_types, and abstract-type
    # resolution lives on the interface itself — see its file.
    class Schema < GraphQL::Schema
      query Query
    end
  end
end
