require "support/client_pages/types/base/object"
require "support/client_pages/interfaces/chats/question"

module SpecSchemas
  module ClientPages
    module Types
      module Chats
        module Questions
          # Mirrors nxt-client-pages-back's Types::Chats::Questions::Base.
          # Each implementer points its proxy_model at the matching admin
          # wrapper (the remote-side counterpart).
          class Base < ClientPages::Types::Base::Object
            implements ClientPages::Interfaces::Chats::Question
          end
        end
      end
    end
  end
end
