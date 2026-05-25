require "support/client_pages/lib/admin/chats/questions/base"

module SpecSchemas
  module ClientPages
    module Admin
      module Chats
        module Questions
          class MultiSelect < Base
            typename "MultiSelectQuestionChat"
            attributes :value
          end
        end
      end
    end
  end
end
