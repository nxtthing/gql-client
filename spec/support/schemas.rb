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
module SpecSchemas
  module_function

  def schema
    @schema ||= build_schema
  end

  def proxy_field_class
    @proxy_field_class ||= Class.new(GraphQL::Schema::Field) do
      include NxtGqlClient::ProxyField
    end
  end

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

    # type Query {
    #   questions: [QuestionChat!]!
    #   article: Article!
    # }
    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :questions, [question_iface], null: false
      field :article, article, null: false
    end

    Class.new(GraphQL::Schema) do
      query query_type
      orphan_types checkbox, select, multi_select, date
      define_singleton_method(:resolve_type) { |*| raise "unused in specs" }
    end
  end
end
