require "nxt_gql_client/model"
require "support/admin/api_wrappers/chat/api"

module SpecSchemas
  module Admin
    module ApiWrappers
      module Chat
        # Wrapper for the chat service's `questions` query. The admin
        # ProxyResolver delegates to this; node_to_gql also reads
        # `.typename` off it for interface-level proxy_model.
        class QuestionChat
          include NxtGqlClient::Model

          # node_to_gql pins under proxy_model.typename — must be the remote
          # name `QuestionChat`, not anything class-derived.
          typename "QuestionChat"

          # Canonical fields the implementer types ask for via the runtime.
          # Subclass wrappers inherit these.
          attributes :id, :value, :view

          def self.api = Api.instance

          query :questions do |response|
            <<~GQL
              query { chat { questions #{response} } }
            GQL
          end
        end
      end
    end
  end
end
