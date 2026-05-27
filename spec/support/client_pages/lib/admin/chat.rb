require "support/client_pages/lib/admin/base"

module SpecSchemas
  module ClientPages
    module Admin
      # Mirrors nxt-client-pages-back's lib/admin/chat.rb — wrapper the
      # ProxyResolver delegates to. `query :questions` declares the entry
      # point; the proxied selection node_to_gql rebuilds is spliced in
      # where `response` interpolates.
      #
      # Prod has `query :conversation` + `mutation :ask_question`; the
      # spec models the polymorphic `questions` round-trip only.
      class Chat < Base
        query :questions do |response|
          <<~GQL
            query { chat { questions #{response} } }
          GQL
        end

        # Returned rows are polymorphic questions, not Chat objects;
        # delegate wrapping to the Question hierarchy so the per-typename
        # implementer is picked up.
        def self.resolve_class(object)
          Chats::Question.resolve_class(object)
        end
      end
    end
  end
end
