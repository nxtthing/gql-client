require "support/admin/api_wrappers/chat/question_chat"

module SpecSchemas
  module Admin
    module ApiWrappers
      module Chat
        # node_to_gql reads `proxy_model.typename` off implementer types
        # when rebuilding inline fragments — needs to be the implementer's
        # remote graphql_name. Inherits the QuestionChat wrapper so it
        # carries the same `query :questions` / api wiring.
        class CheckboxQuestionChat < QuestionChat
          typename "CheckboxQuestionChat"
        end
      end
    end
  end
end
