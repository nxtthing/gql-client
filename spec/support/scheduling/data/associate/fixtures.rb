module SpecSchemas
  module Scheduling
    module Data
      module Associate
        # Builders for Associate store records. Each builder returns a plain
        # hash with sensible defaults; a spec overrides only the parts it
        # cares about.
        module Fixtures
          module_function

          # A tag row as nxt-scheduling-back stores it: key (the filter
          # dimension) plus value.
          def tag(key: "training", value: "Recruiter_Academy")
            { key: key, value: value }
          end

          # A tenancy-skill row carrying its own tenancy_id and a list of
          # task_names, mirroring AssociateTenancySkills on the server side.
          def tenancy_skill(tenancy_id: "A", task_names: ["Training"])
            { tenancy_id: tenancy_id, task_names: task_names }
          end

          # A full associate. Defaults give one tag per category and two
          # tenancy-skills. Pass `tags:` / `tenancy_skills:` to replace a
          # slice wholesale.
          def associate(id: "assoc-1", tags: nil, tenancy_skills: nil)
            {
              id: id,
              tags: tags || [
                tag(key: "training",        value: "Recruiter_Academy"),
                tag(key: "primaryFunction", value: "Sourcing"),
                tag(key: "type",            value: "Internal")
              ],
              tenancy_skills: tenancy_skills || [
                tenancy_skill(tenancy_id: "A", task_names: ["Training"]),
                tenancy_skill(tenancy_id: "B", task_names: ["Meeting"])
              ]
            }
          end
        end
      end
    end
  end
end
