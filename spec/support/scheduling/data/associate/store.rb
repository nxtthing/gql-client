require "support/scheduling/data/associate/fixtures"

module SpecSchemas
  module Scheduling
    module Data
      module Associate
        # In-memory store the scheduling-tool resolvers read from. A spec
        # seeds it before issuing a query; resolvers serve straight out of
        # it. This is the only place test data lives — the schema itself is
        # fully executable.
        module Store
          module_function

          def associates
            @associates ||= []
          end

          def reset!
            @associates = []
          end

          # Adds an associate built from Fixtures.associate; any keyword
          # args override the fixture defaults. `add_associate` with no args
          # yields a complete, queryable associate.
          def add_associate(**overrides)
            associates << Fixtures.associate(**overrides)
          end
        end
      end
    end
  end
end
