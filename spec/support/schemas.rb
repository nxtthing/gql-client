require "support/proxy_model_stub"
require "support/proxy_field_class"
require "support/admin/schema"
require "support/scheduling_tool/schema"

# Spec-only GraphQL schemas, laid out one type per file under
# spec/support/{admin,scheduling_tool}/types/ — mirroring how the host app
# organises app/graphql/types.
#
# - SpecSchemas.schema        — admin-back-side schema. The forward path
#   (node_to_gql) needs Ruby classes because it depends on ProxyField /
#   proxy_model, which can't be expressed in SDL. It also carries the
#   remote-shaped `Associate` so the reverse path (transform_response) can
#   run against the same schema.
# - SpecSchemas.remote_schema — standalone scheduling-tool schema, loaded by
#   proxy_e2e_spec through GraphQL::Client.
module SpecSchemas
  module_function

  def schema
    Admin::Schema
  end

  def remote_schema
    SchedulingTool::Schema
  end
end
