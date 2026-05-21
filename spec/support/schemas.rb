require "graphql"
require "nxt_gql_client/proxy_field"

# Stand-in for the host app's "remote" model reference. node_to_gql only
# reads `proxy_model.typename`, so a struct is enough.
ProxyModelStub = Struct.new(:typename) unless defined?(ProxyModelStub)

# A single Ruby-DSL GraphQL schema shared by both the forward (node_to_gql)
# and the reverse (transform_response) specs. The forward path needs Ruby
# classes because it depends on ProxyField/proxy_model, which can't be
# expressed in SDL; GraphQL::Client happily accepts the same Ruby schema for
# the reverse path, so SDL is unnecessary.
#
# Each block below carries the SDL it mirrors so the schema reads top-down.
# rubocop:disable Metrics/ModuleLength
module SpecSchemas
  module_function

  def schema
    @schema ||= build_schema
  end

  # Separate ruby-defined schema that mirrors the *remote* (scheduling-tool)
  # GraphQL service. The wrapper model in proxy_e2e_spec loads this one via
  # GraphQL::Client. Splitting from the admin-back schema lets the wrapper
  # use the nested-action shape (`associate { search }`) the production
  # wrappers expect, without clashing with the bare `associate` field on
  # the admin-back side.
  def remote_schema
    @remote_schema ||= build_remote_schema
  end

  def proxy_field_class
    @proxy_field_class ||= Class.new(GraphQL::Schema::Field) do
      include NxtGqlClient::ProxyField
    end
  end

  # rubocop:disable Metrics/MethodLength
  def build_schema
    pfc = proxy_field_class

    # interface QuestionChat { id: ID! }
    question_iface = Module.new do
      include GraphQL::Schema::Interface

      graphql_name "QuestionChat"
      field :id, GraphQL::Types::ID, null: false

      definition_methods do
        def proxy_model = ProxyModelStub.new("QuestionChat")
      end
    end

    # type CheckboxQuestionChat implements QuestionChat {
    #   id: ID!
    #   value: Boolean!
    # }
    checkbox = Class.new(GraphQL::Schema::Object) do
      graphql_name "CheckboxQuestionChat"
      implements question_iface
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :value, GraphQL::Types::Boolean, null: false
      define_singleton_method(:proxy_model) { ProxyModelStub.new("CheckboxQuestionChat") }
    end

    # type SelectQuestionChat implements QuestionChat {
    #   id: ID!
    #   value: String
    #   view: String!
    # }
    select = Class.new(GraphQL::Schema::Object) do
      graphql_name "SelectQuestionChat"
      implements question_iface
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :value, GraphQL::Types::String, null: true
      field :view, GraphQL::Types::String, null: false
      define_singleton_method(:proxy_model) { ProxyModelStub.new("SelectQuestionChat") }
    end

    # type MultiSelectQuestionChat implements QuestionChat {
    #   id: ID!
    #   value: [String!]!
    # }
    multi_select = Class.new(GraphQL::Schema::Object) do
      graphql_name "MultiSelectQuestionChat"
      implements question_iface
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :value, [GraphQL::Types::String], null: false
      define_singleton_method(:proxy_model) { ProxyModelStub.new("MultiSelectQuestionChat") }
    end

    # type DateQuestionChat implements QuestionChat {
    #   id: ID!
    #   value: ISO8601Date
    #   view: String!
    # }
    date = Class.new(GraphQL::Schema::Object) do
      graphql_name "DateQuestionChat"
      implements question_iface
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :value, GraphQL::Types::ISO8601Date, null: true
      field :view, GraphQL::Types::String, null: false
      define_singleton_method(:proxy_model) { ProxyModelStub.new("DateQuestionChat") }
    end

    # type Author { id: ID! fullName: String! }
    author = Class.new(GraphQL::Schema::Object) do
      graphql_name "Author"
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :full_name, GraphQL::Types::String, null: false
    end

    # type Article {
    #   id: ID!
    #   title: String!
    #   author(revision: Int): Author!   # proxied to remote `writer`
    # }
    article = Class.new(GraphQL::Schema::Object) do
      graphql_name "Article"
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :title, GraphQL::Types::String, null: false
      field :author, author, null: false, proxy_alias: "writer" do
        argument :revision, GraphQL::Types::Int, required: false
      end
    end

    # type Tag { value: String! }
    tag = Class.new(GraphQL::Schema::Object) do
      graphql_name "Tag"
      field_class pfc
      field :value, GraphQL::Types::String, null: false
    end

    # admin-back's tags_field uses an enum return type — that's why the
    # frontend writes the field bare (`trainings` without `{ value }`),
    # which in turn keeps node_to_gql from rebuilding nested children on
    # top of the proxy_alias string. Mirror that here so e2e behaviour
    # matches prod.
    tag_value = Class.new(GraphQL::Schema::Enum) do
      graphql_name "TagValue"
      value "Recruiter_Academy"
      value "Customer_Service"
      value "Phone_Interview_101"
      value "Phone_Interviewer"
      value "Sourcing"
      value "NXT_Seasonal"
      value "Internal"
    end

    # input TagsFilter { keys: [String!]! }
    tags_filter = Class.new(GraphQL::Schema::InputObject) do
      graphql_name "TagsFilter"
      argument :keys, [GraphQL::Types::String], required: true
    end

    # type AssociateSchedulingTool {
    #   id: ID!
    #   trainings:        [Tag!]!   # proxied to remote `tags(filter: {keys: ["training"]})`
    #   primaryFunctions: [Tag!]!   # proxied to remote `tags(filter: {keys: ["primaryFunction"]})`
    #   types:            [Tag!]!   # proxied to remote `tags(filter: {keys: ["type"]})`
    # }
    # Client-facing (admin-back) shape: three separate fields whose proxy_alias
    # carries the literal remote selection text. `node_to_gql` is what exercises
    # this side. The admin-back graphql_name (`AssociateSchedulingTool`) is
    # deliberately different from the proxy_model.typename (`Associate`) — that
    # mismatch is the prod reality and what preserved_aliases must survive.
    # The `primary_functions` alias is intentionally written snake_case in the
    # proxy_alias string — that's what admin-back's tags_field helper produces
    # via `gql(alias_name: :primary_functions)`. node_to_gql then runs
    # `field_name.camelize(:lower)` on the whole proxy_alias string, so the
    # alias reaches the remote camelCased (`primaryFunctions:`). The pin must
    # match that camelCased form, not the snake_case one we wrote here.
    # rubocop:disable Layout/LineLength
    associate = Class.new(GraphQL::Schema::Object) do
      graphql_name "AssociateSchedulingTool"
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :trainings, [tag_value], null: false,
                                     proxy_alias: 'trainings: tags(filter: { keys: ["training"] }) { value }'
      field :primary_functions, [tag_value], null: false,
                                             proxy_alias: 'primary_functions: tags(filter: { keys: ["primaryFunction"] }) { value }'
      field :types, [tag_value], null: false,
                                 proxy_alias: 'types: tags(filter: { keys: ["type"] }) { value }'
      %i[trainings primary_functions types].each do |name|
        # admin-back resolver: data lands in `object.object[:trainings]` as
        # `[{value: "X"}, ...]` (the tagged remote response); flatten it
        # to the enum's bare values for the consumer.
        define_method(name) { object.object[name].map { |row| row[:value] } }
      end
      # Ordinary non-proxy field. The frontend is free to alias it with
      # different arguments (`a: tenancySkills(t1) b: tenancySkills(t2)`);
      # those aliases reach the remote verbatim and come back under the
      # same alias keys. To resolve each call against the correct response
      # bucket we look at the ast_node alias.
      field :tenancy_skills, [tag], null: false, extras: [:ast_node] do
        argument :tenancy_ids, [GraphQL::Types::String], required: false
      end
      def tenancy_skills(ast_node:, tenancy_ids: nil) # rubocop:disable Lint/UnusedMethodArgument
        # transform_response collapses single-use frontend aliases back to
        # the canonical schema name and only preserves them as distinct keys
        # when there's a real collision (alias count >= 2). Read the alias
        # first, fall back to canonical.
        alias_key      = ast_node.alias&.underscore&.to_sym
        canonical_key  = ast_node.name.underscore.to_sym
        object.object[alias_key] || object.object[canonical_key]
      end
      define_singleton_method(:proxy_model) { ProxyModelStub.new("Associate") }
    end
    # rubocop:enable Layout/LineLength

    # type Associate {
    #   id: ID!
    #   tags(filter: TagsFilter!): [Tag!]!
    #   tenancySkills(tenancyIds: [String!]): [Tag!]!
    # }
    # Remote-facing (scheduling-tool) shape: a single `tags(filter: ...)` field
    # that the rebuilt admin-back query calls three times under different
    # aliases. `tenancySkills` exists to exercise the frontend-driven alias
    # case where the client itself asks the same field twice under different
    # aliases (`a: tenancySkills(t1) b: tenancySkills(t2)`).
    # transform_response runs against this schema. Its graphql_name matches
    # `AssociateSchedulingTool.proxy_model.typename` — that's the pin-lookup
    # key transform_response uses.
    remote_associate = Class.new(GraphQL::Schema::Object) do
      graphql_name "Associate"
      field_class pfc
      field :id, GraphQL::Types::ID, null: false
      field :tags, [tag], null: false do
        argument :filter, tags_filter, required: true
      end
      field :tenancy_skills, [tag], null: false do
        argument :tenancy_ids, [GraphQL::Types::String], required: false
      end
    end

    # type Query {
    #   questions: [QuestionChat!]!
    #   article: Article!
    #   associate: AssociateSchedulingTool!
    #   remoteAssociate: Associate!
    # }
    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :questions, [question_iface], null: false
      field :article, article, null: false
      field :associate, associate, null: false
      field :remote_associate, remote_associate, null: false
    end

    Class.new(GraphQL::Schema) do
      query query_type
      orphan_types checkbox, select, multi_select, date
      define_singleton_method(:resolve_type) { |*| raise "unused in specs" }
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Standalone "remote service" schema mirroring scheduling-tool.
  # Used by proxy_e2e_spec via GraphQL::Client. Kept tiny — only what
  # the wrapper queries need.
  def build_remote_schema
    tag = Class.new(GraphQL::Schema::Object) do
      graphql_name "Tag"
      field :value, GraphQL::Types::String, null: false
    end

    tags_filter = Class.new(GraphQL::Schema::InputObject) do
      graphql_name "TagsFilter"
      argument :keys, [GraphQL::Types::String], required: true
    end

    remote_associate = Class.new(GraphQL::Schema::Object) do
      graphql_name "Associate"
      field :id, GraphQL::Types::ID, null: false
      field :tags, [tag], null: false do
        argument :filter, tags_filter, required: true
      end
      field :tenancy_skills, [tag], null: false do
        argument :tenancy_ids, [GraphQL::Types::String], required: false
      end
    end

    actions = Class.new(GraphQL::Schema::Object) do
      graphql_name "AssociateActions"
      field :search, remote_associate, null: false
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :associate, actions, null: false
    end

    Class.new(GraphQL::Schema) do
      query query_type
    end
  end
end
# rubocop:enable Metrics/ModuleLength
