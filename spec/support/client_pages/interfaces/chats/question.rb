require "graphql"
require "support/client_pages/lib/admin/chats/question"

module SpecSchemas
  module ClientPages
    module Interfaces
      module Chats
        # Mirrors nxt-client-pages-back's Interfaces::Chats::Question —
        # client-side polymorphic interface. proxy_model points at the
        # admin wrapper, so ProxyResolver / node_to_gql can reach the
        # remote (admin-back) typename via Admin::Chats::Question.typename.
        module Question
          include GraphQL::Schema::Interface

          graphql_name "QuestionChat"
          field :id, GraphQL::Types::String, null: false
          field :label, GraphQL::Types::String, null: false

          definition_methods do
            def proxy_model = SpecSchemas::ClientPages::Admin::Chats::Question

            def resolve_type(object, _context)
              # `object` is the wrapper instance for the question; map it
              # back to the matching implementer by graphql_name.
              orphan_types.find { |type| type.graphql_name == object[:__typename] }
            end
          end
        end
      end
    end
  end
end

require "support/client_pages/types/chats/questions/checkbox"
require "support/client_pages/types/chats/questions/select"
require "support/client_pages/types/chats/questions/multi_select"
require "support/client_pages/types/chats/questions/date"

SpecSchemas::ClientPages::Interfaces::Chats::Question.orphan_types(
  SpecSchemas::ClientPages::Types::Chats::Questions::Checkbox,
  SpecSchemas::ClientPages::Types::Chats::Questions::Select,
  SpecSchemas::ClientPages::Types::Chats::Questions::MultiSelect,
  SpecSchemas::ClientPages::Types::Chats::Questions::Date
)
