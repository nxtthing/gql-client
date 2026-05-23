module SpecSchemas
  module SchedulingTool
    module Data
      module Associate
        # Builders for Associate store records. Each builder returns a plain
        # hash with sensible defaults; a spec overrides only the parts it
        # cares about.
        module Fixtures
          module_function

          # A tag row as the remote `tags(filter:)` field stores it. `keys`
          # is what the filter matches against.
          def tag(value: "Recruiter_Academy", keys: ["training"])
            { value: value, keys: keys }
          end

          # A tenancy-skill row. Carries its own tenancy_id so the
          # argument-filtered `tenancySkills` field can pick the right rows.
          def tenancy_skill(tenancy_id: "A", value: "alpha")
            { tenancy_id: tenancy_id, value: value }
          end

          # A full associate. Defaults give one tag per category and two
          # tenancy-skills — enough for a happy-path query. Pass `tags:` /
          # `tenancy_skills:` to replace a slice wholesale.
          def associate(id: "assoc-1", tags: nil, tenancy_skills: nil)
            {
              id: id,
              tags: tags || [
                tag(value: "Recruiter_Academy", keys: ["training"]),
                tag(value: "Sourcing",          keys: ["primaryFunction"]),
                tag(value: "Internal",          keys: ["type"])
              ],
              tenancy_skills: tenancy_skills || [
                tenancy_skill(tenancy_id: "A", value: "alpha"),
                tenancy_skill(tenancy_id: "B", value: "beta")
              ]
            }
          end
        end
      end
    end
  end
end
