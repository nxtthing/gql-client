require "support/admin/api_wrappers/chat/question_chat"

module SpecSchemas
  module Admin
    module ApiWrappers
      module Chat
        class SelectQuestionChat < QuestionChat
          typename "SelectQuestionChat"
        end
      end
    end
  end
end
