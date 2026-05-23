require "support/admin/schema"
require "support/scheduling_tool/schema"

# Spec-only GraphQL schemas, laid out one type per file under
# spec/support/{admin,scheduling_tool}/ — mirroring how the host app
# organises app/graphql.
#
# - SpecSchemas.schema        — the admin-back schema, prod-shaped (the
#   scheduling-tool tree hangs off a `schedulingTool` resolver). The
#   end-to-end spec executes against it; the node_to_gql /
#   transform_response unit specs reach into it for types and parse
#   selections against it.
# - SpecSchemas.remote_schema — standalone, fully executable scheduling-tool
#   schema (resolvers + DataStore), what the api wrapper talks to.
module SpecSchemas
  module_function

  def schema
    Admin::Schema
  end

  def remote_schema
    SchedulingTool::Schema
  end
end
