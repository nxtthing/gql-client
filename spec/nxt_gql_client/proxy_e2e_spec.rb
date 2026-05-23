require "spec_helper"

# End-to-end: frontend GraphQL queries enter the admin-back schema, the
# GraphQL runtime resolves them through the real ProxyResolver chain, which
# rebuilds the selection against the remote schema via
# `dynamic_query_params`. The remote query runs against a fully executable
# in-process server (scheduling-tool / chat), and the response flows back
# through `transform_response` to the frontend.
#
# Nothing is stubbed but the fixture data, which lives in per-service
# DataStores; the remote-side resolvers serve it themselves.

RSpec.describe "Proxy round-trip via admin-back GraphQL runtime" do
  describe "scheduling-tool" do
    before { SpecSchemas::SchedulingTool::Data::Associate::Store.reset! }

    def run(frontend_query)
      result = SpecSchemas.schema.execute(frontend_query).to_h
      raise "admin schema errors: #{result['errors'].inspect}" if result["errors"]

      result.dig("data", "schedulingTool", "associate", "search")
    end

    it "preserves frontend re-aliases on a non-proxy field across the round-trip" do
      # Default tenancy_skills (A: alpha, B: beta); tags irrelevant here.
      SpecSchemas::SchedulingTool::Data::Associate::Store.add_associate(tags: [])

      search = run(<<~GQL)
        {
          schedulingTool {
            associate {
              search {
                id
                tenancySkillsA: tenancySkills(tenancyIds: ["A"]) { value }
                tenancySkillsB: tenancySkills(tenancyIds: ["B"]) { value }
              }
            }
          }
        }
      GQL

      expect(search).to eq(
        "id" => "assoc-1",
        "tenancySkillsA" => [{ "value" => "alpha" }],
        "tenancySkillsB" => [{ "value" => "beta" }]
      )
    end

    it "preserves proxy_alias-decorated fields alongside frontend re-aliasing" do
      SpecSchemas::SchedulingTool::Data::Associate::Store.add_associate(
        tenancy_skills: [SpecSchemas::SchedulingTool::Data::Associate::Fixtures.tenancy_skill]
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
                tenancySkillsA: tenancySkills(tenancyIds: ["A"]) { value }
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
        "tenancySkillsA" => [{ "value" => "alpha" }]
      )
    end
  end

  describe "chat" do
    before { SpecSchemas::Chat::Data::QuestionChat::Store.reset! }

    def run(frontend_query)
      result = SpecSchemas.schema.execute(frontend_query).to_h
      raise "admin schema errors: #{result['errors'].inspect}" if result["errors"]

      result.dig("data", "chat", "questions")
    end

    it "rebuilds polymorphic per-type aliases through the interface round-trip" do
      SpecSchemas::Chat::Data::QuestionChat::Store.seed_all_kinds

      questions = run(<<~GQL)
        {
          chat {
            questions {
              id
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
                                  "checkboxValue" => true },
                                { "__typename" => "SelectQuestionChat", "id" => "q-select",
                                  "selectValue" => "a", "selectView" => "DROPDOWN" },
                                { "__typename" => "MultiSelectQuestionChat", "id" => "q-multi",
                                  "multiSelectValue" => %w[a b] },
                                { "__typename" => "DateQuestionChat", "id" => "q-date",
                                  "dateValue" => "2026-05-23", "dateView" => "CALENDAR" }
                              ])
    end
  end
end
