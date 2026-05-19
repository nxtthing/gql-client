require "spec_helper"

# node_to_gql must preserve client aliases when rebuilding the proxied query.
RSpec.describe NxtGqlClient::Model do
  let(:schema) { SpecSchemas.schema }

  # Builds an AST node + context for the given query string, positioned at the
  # field selected by `field_name`, plus a `result_class` whose `type` is the
  # corresponding schema type — exactly what dynamic_query_params expects.
  def rebuild(query_string, field_name:, schema_type:)
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
    )[:response_gql]
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
end
