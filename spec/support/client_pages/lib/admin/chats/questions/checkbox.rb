require "support/client_pages/lib/admin/chats/questions/base"

module SpecSchemas
  module ClientPages
    module Admin
      module Chats
        module Questions
          class Checkbox < Base
            typename "CheckboxQuestionChat"
            attributes :value
          end
        end
      end
    end
  end
end
