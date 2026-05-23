require "graphql"
require "support/admin/api_wrappers/chat/question_chat"

module SpecSchemas
  module Admin
    module Interfaces
      # Polymorphic interface — exercises node_to_gql's handling of
      # interface selections. Mirrors admin-back's app/graphql/interfaces.
      module QuestionChat
        include GraphQL::Schema::Interface

        graphql_name "QuestionChat"
        field :id, GraphQL::Types::ID, null: false

        definition_methods do
          def proxy_model = ApiWrappers::Chat::QuestionChat

          # A record carries a `__typename`; pick the implementing type
          # whose graphql_name matches. Knowledge of "which of my types is
          # this object" belongs to the interface, like orphan_types below.
          def resolve_type(object, _context)
            orphan_types.find { |type| type.graphql_name == object[:__typename] }
          end
        end
      end
    end
  end
end

# The implementing object types are reachable only through this interface
# (a field returns QuestionChat, the concrete type is picked at runtime via
# resolve_type), so the schema can't discover them by graph traversal. The
# interface declares them as orphan_types itself — knowledge of "who
# implements me" belongs here, not on the schema.
#
# Required *after* the interface module is defined: each implementer does
# `implements Interfaces::QuestionChat`, which only needs the module to
# exist, so this breaks the interface<->implementer require cycle.
require "support/admin/types/question_chat/checkbox"
require "support/admin/types/question_chat/select"
require "support/admin/types/question_chat/multi_select"
require "support/admin/types/question_chat/date"

SpecSchemas::Admin::Interfaces::QuestionChat.orphan_types(
  SpecSchemas::Admin::Types::QuestionChat::Checkbox,
  SpecSchemas::Admin::Types::QuestionChat::Select,
  SpecSchemas::Admin::Types::QuestionChat::MultiSelect,
  SpecSchemas::Admin::Types::QuestionChat::Date
)
