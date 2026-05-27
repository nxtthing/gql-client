require "graphql"
require "support/admin/types/article"
require "support/admin/resolvers/scheduling_tool/self"
require "support/admin/resolvers/scheduling_tool/remote_associate"
require "support/admin/client_pages/resolvers/chat"

module SpecSchemas
  module Admin
    # Query root. Mirrors the prod admin-back chain:
    #   Query -> schedulingTool -> associate -> search    (proxied to scheduling-back)
    # The chat surface admin-back serves *to client-pages-back* lives on a
    # separate schema (SpecSchemas::Admin::ClientPages::Schema), mirroring
    # admin-back's /client_pages/graphql endpoint. We also expose it under
    # the main schema's `chat` field so unit specs (node_to_gql,
    # transform_response) can reach the polymorphic surface through a
    # single SpecSchemas.admin_schema entry point.
    #
    # `article` and `remoteAssociate` are scaffolding kept for the
    # node_to_gql / transform_response unit specs — Article is a stand-in
    # for "any non-proxy field with arguments and nested children", and
    # remoteAssociate exposes the remote-shaped Associate so reverse-path
    # specs can parse remote-shaped queries against this schema.
    class Query < GraphQL::Schema::Object
      field :scheduling_tool, resolver: Resolvers::SchedulingTool::Self
      field :remote_associate, resolver: Resolvers::SchedulingTool::RemoteAssociate
      field :chat, resolver: ClientPages::Resolvers::Chat
      field :article, Types::Article, null: false

      # Inline scaffold for article unit specs — no domain logic, just a
      # constant payload so the schema is executable.
      def article = { id: "article-1", title: "Hello", author: { id: "author-1", full_name: "Jane Roe" } }
    end

    class Schema < GraphQL::Schema
      query Query

      # Polymorphic QuestionChat resolution lives on its interface
      # (Admin::ClientPages::Interfaces::Chats::Question.resolve_type), so
      # delegate when the runtime needs an abstract type resolved here.
      def self.resolve_type(abstract_type, object, context)
        abstract_type.resolve_type(object, context)
      end
    end
  end
end
