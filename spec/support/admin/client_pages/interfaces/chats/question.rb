require "graphql"

module SpecSchemas
  module Admin
    module ClientPages
      module Interfaces
        module Chats
          # Mirrors nxt-admin-back's ClientPages::Interfaces::Chats::Question
          # — the polymorphic question interface admin-back serves to
          # client-pages-back. Each record carries a `:type` and the
          # interface picks the implementing class by that key, matching
          # prod's `Base.child_classes.index_by(&:name).demodulize`.
          module Question
            include GraphQL::Schema::Interface

            graphql_name "QuestionChat"
            field :id, GraphQL::Types::String, null: false
            field :label, GraphQL::Types::String, null: false

            definition_methods do
              def resolve_type(object, _context)
                orphan_types.find { |type| type.name.demodulize == object[:type] }
              end
            end
          end
        end
      end
    end
  end
end

# Required after the interface module is defined: each implementer does
# `implements ..::Question`, which only needs the module to exist, so this
# breaks the interface<->implementer require cycle. orphan_types is
# populated last, when all implementer constants exist.
require "support/admin/client_pages/types/chats/questions/checkbox"
require "support/admin/client_pages/types/chats/questions/select"
require "support/admin/client_pages/types/chats/questions/multi_select"
require "support/admin/client_pages/types/chats/questions/date"

SpecSchemas::Admin::ClientPages::Interfaces::Chats::Question.orphan_types(
  SpecSchemas::Admin::ClientPages::Types::Chats::Questions::Checkbox,
  SpecSchemas::Admin::ClientPages::Types::Chats::Questions::Select,
  SpecSchemas::Admin::ClientPages::Types::Chats::Questions::MultiSelect,
  SpecSchemas::Admin::ClientPages::Types::Chats::Questions::Date
)
