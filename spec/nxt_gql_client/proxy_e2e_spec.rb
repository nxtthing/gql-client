require "spec_helper"
require "graphql/client"
require "nxt_gql_client/api"
require "nxt_gql_client/model"
require "nxt_gql_client/proxy_resolver"

# End-to-end: a frontend GraphQL query enters the admin-back schema, the
# GraphQL runtime resolves it, our ProxyResolver rebuilds the selection
# against the remote schema via `dynamic_query_params`, sends it to a
# stubbed remote client, and the response flows back through
# `transform_response` to whatever the consumer sees on top of the schema
# response. We assert both halves of the round-trip:
#   (a) the proxied query text the remote actually receives
#   (b) the data block the frontend gets back, keyed by its own aliases
RSpec.describe "Proxy round-trip via admin-back GraphQL runtime" do
  let(:admin_associate) { SpecSchemas.schema.types["AssociateSchedulingTool"] }

  # GraphQL::Client.execute interface — records the rebuilt query and
  # returns a canned response.
  let(:remote_execute) do
    Class.new do
      attr_accessor :last_query, :response

      def execute(document:, operation_name:, variables:, context:) # rubocop:disable Lint/UnusedMethodArgument
        self.last_query = document.to_query_string
        response
      end
    end.new
  end

  let(:remote_api) do
    api = NxtGqlClient::Api.allocate
    api.instance_variable_set(:@url, "stub://remote")
    api.instance_variable_set(
      :@client,
      GraphQL::Client.new(schema: SpecSchemas.remote_schema, execute: remote_execute).tap do |c|
        c.allow_dynamic_queries = true
      end
    )
    api
  end

  # Wrapper that the ProxyResolver delegates `search` to. The query body
  # mirrors what `lib/api_wrappers/scheduling_tool/associate.rb` declares.
  # The dynamic `method_missing` substitutes for production `attributes :id,
  # ...` declarations — frontend aliases vary per test, so we resolve every
  # method call straight to the underlying response hash.
  let(:remote_wrapper) do
    api_ref = remote_api
    Class.new do
      include NxtGqlClient::Model

      define_singleton_method(:api) { api_ref }

      query :search do |response|
        <<~GQL
          query { associate { search #{response} } }
        GQL
      end

      def method_missing(name, *args, **kwargs, &)
        if @object.key?(name)
          @object[name]
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @object.key?(name) || super
      end
    end
  end

  # Admin-back schema: mirrors `Resolvers::SchedulingTool::Associate` —
  # a wrapper resolver returning itself, with `search` underneath that
  # actually goes through ProxyResolver.
  let(:admin_schema) do
    associate_type = admin_associate
    wrapper        = remote_wrapper

    search_resolver = Class.new(GraphQL::Schema::Resolver) do
      include NxtGqlClient::ProxyResolver

      type associate_type, null: false

      # Anonymous classes have no demodulized name; pin the wrapper method
      # name explicitly. proxy_arguments / proxy_context are stubbed too.
      define_method(:proxy_query_name) { "search" }
      define_method(:proxy_context)    { GraphQL::Query::NullContext.instance }
      define_method(:proxy_arguments)  { {} }
      define_method(:proxy_model)      { wrapper }
    end

    actions_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "AssociateActions"
      field :search, resolver: search_resolver
    end

    associate_root_resolver = Class.new(GraphQL::Schema::Resolver) do
      type actions_type, null: false
      define_method(:resolve) { self }
    end

    query_root = Class.new(GraphQL::Schema::Object) do
      graphql_name "AdminQuery"
      field :associate, resolver: associate_root_resolver
    end

    Class.new(GraphQL::Schema) do
      query query_root
    end
  end

  def run(frontend_query)
    result = admin_schema.execute(frontend_query).to_h
    raise "admin schema errors: #{result['errors'].inspect}" if result["errors"]

    result
  end

  it "preserves frontend re-aliases on a non-proxy field across the round-trip" do
    remote_execute.response = {
      "data" => {
        "associate" => {
          "search" => {
            "id" => "assoc-1",
            "tenancySkillsA" => [{ "value" => "alpha" }],
            "tenancySkillsB" => [{ "value" => "beta" }]
          }
        }
      }
    }

    result = run(<<~GQL)
      {
        associate {
          search {
            id
            tenancySkillsA: tenancySkills(tenancyIds: ["A"]) { value }
            tenancySkillsB: tenancySkills(tenancyIds: ["B"]) { value }
          }
        }
      }
    GQL

    # (a) the proxied query forwarded both aliases verbatim
    expect(remote_execute.last_query).to include("tenancySkillsA: tenancySkills")
    expect(remote_execute.last_query).to include("tenancySkillsB: tenancySkills")

    # (b) both buckets survived under their original frontend alias keys
    expect(result.dig("data", "associate", "search")).to eq(
      "id" => "assoc-1",
      "tenancySkillsA" => [{ "value" => "alpha" }],
      "tenancySkillsB" => [{ "value" => "beta" }]
    )
  end

  it "preserves proxy_alias-decorated fields alongside frontend re-aliasing" do
    remote_execute.response = {
      "data" => {
        "associate" => {
          "search" => {
            "id" => "assoc-1",
            "trainings" => [{ "value" => "Recruiter_Academy" }],
            "primaryFunctions" => [{ "value" => "Sourcing" }],
            "types" => [{ "value" => "Internal" }],
            "tenancySkillsA" => [{ "value" => "alpha" }]
          }
        }
      }
    }

    result = run(<<~GQL)
      {
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
    GQL

    # proxy_alias strings inlined into the rebuilt query (graphql-ruby's
    # printer normalises whitespace, so match the bits that matter).
    sent = remote_execute.last_query
    expect(sent).to match(/trainings:\s*tags\(filter:\s*\{\s*keys:\s*\["training"\]\s*\}\)\s*\{\s*value\s*\}/)
    expect(sent).to match(/primaryFunctions:\s*tags\(filter:\s*\{\s*keys:\s*\["primaryFunction"\]\s*\}\)/)
    expect(sent).to match(/types:\s*tags\(filter:\s*\{\s*keys:\s*\["type"\]\s*\}\)/)
    expect(sent).to include("tenancySkillsA: tenancySkills")

    # frontend sees the proxied enum values flat-mapped by the admin-back
    # resolver, and the frontend-aliased tenancy_skills bucket intact.
    expect(result.dig("data", "associate", "search")).to eq(
      "id" => "assoc-1",
      "trainings" => ["Recruiter_Academy"],
      "primaryFunctions" => ["Sourcing"],
      "types" => ["Internal"],
      "tenancySkillsA" => [{ "value" => "alpha" }]
    )
  end
end
