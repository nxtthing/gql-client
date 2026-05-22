require "graphql"

module SpecSchemas
  module Admin
    module Types
      class TagValue < GraphQL::Schema::Enum
        description <<~DESC
          Enum return type of admin-back's tags_field. Being an enum (not an
          object) is what lets the frontend write `trainings` bare, with no
          `{ value }` — which keeps node_to_gql from rebuilding nested
          children on top of the proxy_alias string.
        DESC

        value "Recruiter_Academy"
        value "Customer_Service"
        value "Phone_Interview_101"
        value "Phone_Interviewer"
        value "Sourcing"
        value "NXT_Seasonal"
        value "Internal"
      end
    end
  end
end
