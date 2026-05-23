module SpecSchemas
  module Chat
    module Data
      module QuestionChat
        # Builders for question-chat store records. Each record carries a
        # `__typename` so the QuestionChat interface can resolve the concrete
        # type, plus the fields that type exposes.
        module Fixtures
          module_function

          def checkbox(id: "q-checkbox", value: true)
            { __typename: "CheckboxQuestionChat", id: id, value: value }
          end

          def select(id: "q-select", value: "a", view: "DROPDOWN")
            { __typename: "SelectQuestionChat", id: id, value: value, view: view }
          end

          def multi_select(id: "q-multi", value: %w[a b])
            { __typename: "MultiSelectQuestionChat", id: id, value: value }
          end

          def date(id: "q-date", value: "2026-05-23", view: "CALENDAR")
            { __typename: "DateQuestionChat", id: id, value: value, view: view }
          end

          # One question of each kind — a full polymorphic list.
          def all_kinds
            [checkbox, select, multi_select, date]
          end
        end
      end
    end
  end
end
