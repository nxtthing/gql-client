module SpecSchemas
  module Admin
    module Data
      module Article
        # Builders for Article store records. Defaults give a complete,
        # queryable article; a spec overrides only what it needs.
        module Fixtures
          module_function

          def author(id: "author-1", full_name: "Jane Roe")
            { id: id, full_name: full_name }
          end

          def article(id: "article-1", title: "Hello", author: nil)
            {
              id: id,
              title: title,
              author: author || self.author
            }
          end
        end
      end
    end
  end
end
