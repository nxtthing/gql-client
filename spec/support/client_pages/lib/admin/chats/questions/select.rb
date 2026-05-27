require "support/client_pages/lib/admin/chats/questions/base"

module SpecSchemas
  module ClientPages
    module Admin
      module Chats
        module Questions
          class Select < Base
            typename "SelectQuestionChat"
            attributes :value, :view
          end
        end
      end
    end
  end
end
