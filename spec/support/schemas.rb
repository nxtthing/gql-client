require "support/admin/schema"
require "support/client_pages/schema"
require "support/scheduling/schema"

# Spec-only GraphQL schemas, one per real backend the gem touches.
# Each lives under spec/support/<service>/ mirroring how the real repo
# organises app/graphql.
#
# Direction of traffic:
#   client-pages-back ──gql──▶ admin-back ──gql──▶ scheduling-back
#
# - SpecSchemas.client_pages_schema — consumer of admin-back chat surface
#   (mirrors nxt-client-pages-back).
# - SpecSchemas.admin_schema        — serves chat to client-pages, calls
#   scheduling-back for scheduling-tool data. Mirrors nxt-admin-back's
#   ClientPages::Schema plus its main admin Query.
# - SpecSchemas.scheduling_schema   — source of scheduling-tool data
#   (mirrors nxt-scheduling-back's Schemas::Admin).
#
# Unit specs (model_node_to_gql, query_transform_response) reach into
# `admin_schema.types[...]` and parse selections against it; e2e specs
# execute real queries through the runtime and ProxyResolver chain.
module SpecSchemas
  module_function

  def admin_schema
    Admin::Schema
  end

  def client_pages_schema
    ClientPages::Schema
  end

  def scheduling_schema
    Scheduling::Schema
  end

  # Back-compat aliases for unit specs that pre-date the rename. Will be
  # removed once those specs migrate to admin_schema.
  def schema = admin_schema
  def remote_schema = scheduling_schema
end
