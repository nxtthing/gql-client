require "graphql"
require "support/chat/types/base/field"

module SpecSchemas
  module Chat
    module Types
      module Base
        class Object < GraphQL::Schema::Object
          field_class Field
        end
      end
    end
  end
end
