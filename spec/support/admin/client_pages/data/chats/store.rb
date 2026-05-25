require "support/admin/client_pages/data/chats/fixtures"

module SpecSchemas
  module Admin
    module ClientPages
      module Data
        module Chats
          # In-memory store for chat questions admin-back serves to
          # client-pages-back. A spec seeds it; the chat resolver returns
          # the list straight out of it.
          module Store
            module_function

            def questions
              @questions ||= []
            end

            def reset!
              @questions = []
            end

            # Appends one question built from the matching Fixtures builder.
            # `kind` is :checkbox / :text / :select / :date.
            def add_question(kind, **overrides)
              questions << Fixtures.public_send(kind, **overrides)
            end

            def seed_all_kinds
              @questions = Fixtures.all_kinds
            end
          end
        end
      end
    end
  end
end
