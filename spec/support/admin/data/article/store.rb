require "support/admin/data/article/fixtures"

module SpecSchemas
  module Admin
    module Data
      module Article
        # In-memory store for the `article` field. A spec seeds it; the
        # resolver serves straight out of it.
        module Store
          module_function

          def article
            @article ||= Fixtures.article
          end

          def reset!
            @article = nil
          end

          # Replaces the stored article; keyword args override Fixtures
          # defaults.
          def set_article(**overrides)
            @article = Fixtures.article(**overrides)
          end
        end
      end
    end
  end
end
