require "graphql"
require "support/admin/types/question_chat"
require "support/admin/types/checkbox_question_chat"
require "support/admin/types/select_question_chat"
require "support/admin/types/multi_select_question_chat"
require "support/admin/types/date_question_chat"
require "support/admin/types/article"
require "support/admin/types/associate_scheduling_tool"
require "support/scheduling_tool/types/associate"

module SpecSchemas
  module Admin
    class Query < GraphQL::Schema::Object
      field :questions, [Types::QuestionChat], null: false
      field :article, Types::Article, null: false
      field :associate, Types::AssociateSchedulingTool, null: false
      field :remote_associate, SpecSchemas::SchedulingTool::Types::Associate, null: false
    end

    # Admin-back-side spec schema. Carries both the client-facing
    # AssociateSchedulingTool (forward / node_to_gql specs) and the
    # remote-shaped scheduling-tool Associate (reverse / transform_response
    # specs), so one shared schema serves both directions.
    class Schema < GraphQL::Schema
      query Query
      orphan_types Types::CheckboxQuestionChat, Types::SelectQuestionChat,
                   Types::MultiSelectQuestionChat, Types::DateQuestionChat
      def self.resolve_type(*) = raise "unused in specs"
    end
  end
end
