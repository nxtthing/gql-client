require "spec_helper"

# End-to-end: frontend GraphQL queries enter the consumer schema, the
# GraphQL runtime resolves them through the real ProxyResolver chain,
# which rebuilds the selection against the remote schema via
# `dynamic_query_params`. The remote query runs against a fully executable
# in-process server, and the response flows back through
# `transform_response` to the consumer.
#
# Nothing is stubbed but the fixture data, which lives in per-service
# data stores; the remote-side resolvers serve it themselves.

RSpec.describe "Proxy round-trip via real GraphQL runtimes" do
  describe "admin-back -> scheduling-back" do
    before { SpecSchemas::Scheduling::Data::Associate::Store.reset! }

    def run(frontend_query)
      result = SpecSchemas.admin_schema.execute(frontend_query).to_h
      raise "admin schema errors: #{result['errors'].inspect}" if result["errors"]

      result.dig("data", "schedulingTool", "associate", "search")
    end

    it "preserves frontend re-aliases on a non-proxy field across the round-trip" do
      # Default tenancy_skills (A: Training, B: Meeting); tags irrelevant here.
      SpecSchemas::Scheduling::Data::Associate::Store.add_associate(tags: [])

      search = run(<<~GQL)
        {
          schedulingTool {
            associate {
              search {
                id
                tenancySkillsA: tenancySkills(tenancyIds: ["A"]) { tenancyId taskNames }
                tenancySkillsB: tenancySkills(tenancyIds: ["B"]) { tenancyId taskNames }
              }
            }
          }
        }
      GQL

      expect(search).to eq(
        "id" => "assoc-1",
        "tenancySkillsA" => [{ "tenancyId" => "A", "taskNames" => ["Training"] }],
        "tenancySkillsB" => [{ "tenancyId" => "B", "taskNames" => ["Meeting"] }]
      )
    end

    it "preserves proxy_alias-decorated fields alongside frontend re-aliasing" do
      SpecSchemas::Scheduling::Data::Associate::Store.add_associate(
        tenancy_skills: [SpecSchemas::Scheduling::Data::Associate::Fixtures.tenancy_skill]
      )

      search = run(<<~GQL)
        {
          schedulingTool {
            associate {
              search {
                id
                trainings
                primaryFunctions
                types
                tenancySkillsA: tenancySkills(tenancyIds: ["A"]) { tenancyId taskNames }
              }
            }
          }
        }
      GQL

      expect(search).to eq(
        "id" => "assoc-1",
        "trainings" => ["Recruiter_Academy"],
        "primaryFunctions" => ["Sourcing"],
        "types" => ["Internal"],
        "tenancySkillsA" => [{ "tenancyId" => "A", "taskNames" => ["Training"] }]
      )
    end
  end

  describe "client-pages-back -> admin-back" do
    before { SpecSchemas::Admin::ClientPages::Data::Chats::Store.reset! }

    def run(frontend_query)
      result = SpecSchemas.client_pages_schema.execute(frontend_query).to_h
      raise "client_pages schema errors: #{result['errors'].inspect}" if result["errors"]

      result.dig("data", "chat", "questions")
    end

    it "rebuilds polymorphic per-type aliases through the interface round-trip" do
      SpecSchemas::Admin::ClientPages::Data::Chats::Store.seed_all_kinds

      questions = run(<<~GQL)
        {
          chat {
            questions {
              id
              label
              __typename
              ... on CheckboxQuestionChat { checkboxValue: value }
              ... on SelectQuestionChat { selectValue: value selectView: view }
              ... on MultiSelectQuestionChat { multiSelectValue: value }
              ... on DateQuestionChat { dateValue: value dateView: view }
            }
          }
        }
      GQL

      # Each per-type alias resolves against its concrete remote field and
      # survives the round-trip under the original alias key.
      expect(questions).to eq([
                                { "__typename" => "CheckboxQuestionChat", "id" => "q-checkbox",
                                  "label" => "Agree?", "checkboxValue" => true },
                                { "__typename" => "SelectQuestionChat", "id" => "q-select",
                                  "label" => "Pick one",
                                  "selectValue" => "a", "selectView" => "DROPDOWN" },
                                { "__typename" => "MultiSelectQuestionChat", "id" => "q-multi",
                                  "label" => "Pick many",
                                  "multiSelectValue" => %w[a b] },
                                { "__typename" => "DateQuestionChat", "id" => "q-date",
                                  "label" => "When?",
                                  "dateValue" => "2026-05-25", "dateView" => "CALENDAR" }
                              ])
    end
  end
end
