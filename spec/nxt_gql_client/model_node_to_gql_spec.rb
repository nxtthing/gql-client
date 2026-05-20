require "spec_helper"

# node_to_gql must preserve client aliases when rebuilding the proxied query.
RSpec.describe NxtGqlClient::Model do
  let(:schema) { SpecSchemas.schema }

  # Builds an AST node + context for the given query string, positioned at the
  # field selected by `field_name`, plus a `result_class` whose `type` is the
  # corresponding schema type — exactly what dynamic_query_params expects.
  def rebuild(query_string, field_name:, schema_type:)
    rebuild_params(query_string, field_name:, schema_type:)[:response_gql]
  end

  def rebuild_params(query_string, field_name:, schema_type:)
    document = GraphQL::Language::Parser.parse(query_string)
    query = GraphQL::Query.new(schema, document: document)
    context = query.context

    operation = document.definitions.find { |d| d.is_a?(GraphQL::Language::Nodes::OperationDefinition) }
    node = operation.selections.find { |s| s.name == field_name }

    result_class = Struct.new(:type).new(schema_type)

    NxtGqlClient::Model.dynamic_query_params(
      node: node,
      result_class: result_class,
      context: context
    )
  end

  describe ".node_to_gql alias handling" do
    it "preserves a simple field alias (foo: bar stays foo: bar)" do
      gql = rebuild(
        "{ article { renamedTitle: title } }",
        field_name: "article",
        schema_type: schema.types["Article"]
      )

      expect(gql).to include("renamedTitle: title")
    end

    it "does not add an alias (or stray colon) when none is present" do
      gql = rebuild(
        "{ article { title } }",
        field_name: "article",
        schema_type: schema.types["Article"]
      )

      expect(gql).to include("title")
      expect(gql).not_to match(/title\s*:/)
      expect(gql).not_to match(/:\s*title/)
    end

    it "keeps the alias for a field with arguments and nested children" do
      gql = rebuild(
        "{ article { creator: author(revision: 1) { fullName } } }",
        field_name: "article",
        schema_type: schema.types["Article"]
      )

      # proxy_alias: author -> writer; client alias `creator` wraps it.
      expect(gql).to match(/creator:\s*writer\(revision:\s*1\)\s*\{[^}]*fullName/m)
    end

    it "does not duplicate the alias when it equals the rebuilt field name" do
      gql = rebuild(
        "{ article { title: title } }",
        field_name: "article",
        schema_type: schema.types["Article"]
      )

      # alias == field name => no redundant "title: title"
      expect(gql).not_to include("title: title")
      expect(gql).to include("title")
    end

    it "rebuilds a polymorphic interface preserving every per-type alias" do
      query_string = <<~GQL
        {
          questions {
            id
            ... on CheckboxQuestionChat { checkboxValue: value }
            ... on SelectQuestionChat { selectValue: value selectView: view }
            ... on MultiSelectQuestionChat { multiSelectValue: value }
            ... on DateQuestionChat { dateValue: value dateView: view }
          }
        }
      GQL

      gql = rebuild(
        query_string,
        field_name: "questions",
        schema_type: schema.types["QuestionChat"]
      )

      expect(gql).to include("checkboxValue: value")
      expect(gql).to include("selectValue: value")
      expect(gql).to include("selectView: view")
      expect(gql).to include("multiSelectValue: value")
      expect(gql).to include("dateValue: value")
      expect(gql).to include("dateView: view")

      # Every `value`/`view` must be aliased — no bare selection.
      gql.scan(/(\S+\s+)?\b(value|view)\b/).each do |preceding, name|
        expect(preceding).to match(/:\s*\z/),
                             "found a `#{name}` not preceded by an alias in: #{gql}"
      end
    end

    it "keeps the client alias alongside proxy_alias remapping" do
      # proxy_alias: author -> writer; client alias `byline` wraps the remapped name.
      gql = rebuild(
        "{ article { byline: author { fullName } } }",
        field_name: "article",
        schema_type: schema.types["Article"]
      )

      expect(gql).to match(/byline:\s*writer\s*\{/)
      expect(gql).not_to match(/(^|[^:])\bauthor\b/)
    end
  end

  describe ".dynamic_query_params preserved_aliases" do
    # Pins are stored as Hash{owner_typename => {alias_key => client_field_name}}
    # so a pin on one type can't bleed into a sibling subtree, and so the
    # response transformer can rewrite the alias to its client-side name
    # rather than just leaving it untouched.
    it "maps the alias key to the client-side field name for a proxy_alias-decorated field" do
      params = rebuild_params(
        "{ associate { trainings { value } } }",
        field_name: "associate",
        schema_type: schema.types["AssociateSchedulingTool"]
      )

      expect(params[:preserved_aliases]).to eq("Associate" => { "trainings" => "trainings" })
    end

    it "maps every alias to its client-side field name when proxy_alias siblings share one remote field" do
      params = rebuild_params(
        "{ associate { trainings { value } primaryFunctions { value } types { value } } }",
        field_name: "associate",
        schema_type: schema.types["AssociateSchedulingTool"]
      )

      # Pin values are the raw `field.name` (graphql-ruby's camelCased form).
      # transform_response runs `.underscore` on the result key, so values stay
      # camelCased here and arrive at the wrapper as `:primary_functions`.
      expect(params[:preserved_aliases]).to eq(
        "Associate" => {
          "trainings" => "trainings",
          "primaryFunctions" => "primaryFunctions",
          "types" => "types"
        }
      )
    end

    it "camelizes a snake_case proxy_alias key to match the camelized remote response key" do
      # `primary_functions` in the spec schema's proxy_alias is written
      # snake_case (admin-back's tags_field generates it that way), but
      # node_to_gql emits the proxy_alias via `field_name.camelize(:lower)`,
      # so the remote sees `primaryFunctions:` and answers under that key.
      # The pin key has to match the *emitted* alias.
      params = rebuild_params(
        "{ associate { primaryFunctions { value } } }",
        field_name: "associate",
        schema_type: schema.types["AssociateSchedulingTool"]
      )

      expect(params[:response_gql]).to include("primaryFunctions: tags")
      expect(params[:response_gql]).not_to include("primary_functions: tags")
      expect(params[:preserved_aliases]).to eq("Associate" => { "primaryFunctions" => "primaryFunctions" })
    end

    it "does not collect anything for selections without proxy_alias" do
      params = rebuild_params(
        "{ article { title } }",
        field_name: "article",
        schema_type: schema.types["Article"]
      )

      expect(params[:preserved_aliases]).to be_empty
    end

    it "does not collect a proxy_alias without a `:` prefix (no alias keyed in)" do
      # Article.author has proxy_alias: "writer" — no `:`, so nothing to pin.
      params = rebuild_params(
        "{ article { author { fullName } } }",
        field_name: "article",
        schema_type: schema.types["Article"]
      )

      expect(params[:preserved_aliases]).to be_empty
    end

    it "collects aliases declared inside an InlineFragment, owned by the inline fragment type" do
      # Place the proxy_alias-decorated selections inside an inline fragment to
      # exercise the recursive node_to_gql branch.
      query_string = <<~GQL
        {
          questions {
            ... on CheckboxQuestionChat {
              checkboxValue: value
            }
          }
          associate {
            ... on AssociateSchedulingTool {
              trainings { value }
              types { value }
            }
          }
        }
      GQL

      params = rebuild_params(
        query_string,
        field_name: "associate",
        schema_type: schema.types["AssociateSchedulingTool"]
      )

      expect(params[:preserved_aliases]).to eq(
        "Associate" => { "trainings" => "trainings", "types" => "types" }
      )
    end

    it "collects aliases declared inside a FragmentSpread, owned by the fragment's type" do
      query_string = <<~GQL
        fragment AssociateTags on AssociateSchedulingTool {
          trainings { value }
          primaryFunctions { value }
        }
        { associate { ...AssociateTags types { value } } }
      GQL

      params = rebuild_params(
        query_string,
        field_name: "associate",
        schema_type: schema.types["AssociateSchedulingTool"]
      )

      # Aliases inside the fragment are owned by Associate (the fragment's
      # `on` type) — same owner as the inline `types` selection, so they
      # all land in one Associate-keyed map.
      expect(params[:preserved_aliases]).to eq(
        "Associate" => {
          "trainings" => "trainings",
          "primaryFunctions" => "primaryFunctions",
          "types" => "types"
        }
      )
    end
  end

  describe NxtGqlClient::ProxyField, "#proxy_alias_key" do
    let(:trainings_field) { SpecSchemas.schema.types["AssociateSchedulingTool"].fields["trainings"] }
    let(:author_field) { SpecSchemas.schema.types["Article"].fields["author"] }
    let(:title_field) { SpecSchemas.schema.types["Article"].fields["title"] }

    it "extracts the alias identifier from a `name: real(...)` proxy_alias string" do
      expect(trainings_field.proxy_alias_key).to eq("trainings")
    end

    it "returns nil when proxy_alias has no `:` prefix" do
      expect(author_field.proxy_alias_key).to be_nil
    end

    it "returns nil when proxy_alias was never set" do
      expect(title_field.proxy_alias_key).to be_nil
    end
  end
end
