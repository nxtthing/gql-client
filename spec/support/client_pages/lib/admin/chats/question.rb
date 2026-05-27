require "support/client_pages/lib/admin/base"

module SpecSchemas
  module ClientPages
    module Admin
      module Chats
        # Mirrors nxt-client-pages-back's lib/admin/chats/question.rb. The
        # interface uses this as its proxy_model; node_to_gql reads
        # `.typename` off it for interface-level proxying. typename matches
        # the remote (admin-back) interface graphql_name.
        class Question < Base
          typename "QuestionChat"

          attributes :id, :label
        end
      end
    end
  end
end
