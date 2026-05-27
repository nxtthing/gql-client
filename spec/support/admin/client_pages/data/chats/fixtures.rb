module SpecSchemas
  module Admin
    module ClientPages
      module Data
        module Chats
          # Builders for chat-question store records the admin schema serves
          # to client-pages-back. Each record carries a `:type` (the
          # short-form admin uses to pick the implementing class — mirrors
          # prod ClientPages::Types::Chats::Questions::Base.child_classes
          # lookup via name.demodulize), plus the fields that type exposes.
          module Fixtures
            module_function

            def checkbox(id: "q-checkbox", label: "Agree?", value: true)
              { type: "Checkbox", id: id, label: label, value: value }
            end

            def select(id: "q-select", label: "Pick one", value: "a", view: "DROPDOWN")
              { type: "Select", id: id, label: label, value: value, view: view }
            end

            def multi_select(id: "q-multi", label: "Pick many", value: %w[a b])
              { type: "MultiSelect", id: id, label: label, value: value }
            end

            def date(id: "q-date", label: "When?", value: "2026-05-25", view: "CALENDAR")
              { type: "Date", id: id, label: label, value: value, view: view }
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
end
