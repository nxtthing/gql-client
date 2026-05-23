require "support/chat/data/question_chat/fixtures"

module SpecSchemas
  module Chat
    module Data
      module QuestionChat
        # In-memory store for the polymorphic `questions` field. A spec
        # seeds it; the resolver serves the list straight out of it.
        module Store
          module_function

          def questions
            @questions ||= []
          end

          def reset!
            @questions = []
          end

          # Appends one question built from the matching Fixtures builder.
          # `kind` is :checkbox / :select / :multi_select / :date.
          def add_question(kind, **overrides)
            questions << Fixtures.public_send(kind, **overrides)
          end

          # Seeds one question of every kind.
          def seed_all_kinds
            @questions = Fixtures.all_kinds
          end
        end
      end
    end
  end
end
