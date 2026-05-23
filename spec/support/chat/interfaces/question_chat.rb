require "graphql"

module SpecSchemas
  module Chat
    module Interfaces
      # Polymorphic interface on the chat service side. The admin wrapper
      # proxies queries against this; the spec exercises polymorphic
      # round-trip aliases (`checkboxValue: value` etc.) end to end.
      module QuestionChat
        include GraphQL::Schema::Interface

        graphql_name "QuestionChat"
        field :id, GraphQL::Types::ID, null: false

        definition_methods do
          # Records carry a `__typename`; pick the implementing type whose
          # graphql_name matches.
          def resolve_type(object, _context)
            orphan_types.find { |type| type.graphql_name == object[:__typename] }
          end
        end
      end
    end
  end
end

# Required after the interface module is defined: each implementer does
# `implements Interfaces::QuestionChat`, which only needs the module to
# exist, so this breaks the interface<->implementer require cycle.
require "support/chat/types/question_chat/checkbox"
require "support/chat/types/question_chat/select"
require "support/chat/types/question_chat/multi_select"
require "support/chat/types/question_chat/date"

SpecSchemas::Chat::Interfaces::QuestionChat.orphan_types(
  SpecSchemas::Chat::Types::QuestionChat::Checkbox,
  SpecSchemas::Chat::Types::QuestionChat::Select,
  SpecSchemas::Chat::Types::QuestionChat::MultiSelect,
  SpecSchemas::Chat::Types::QuestionChat::Date
)
