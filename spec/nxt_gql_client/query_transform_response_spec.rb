require "spec_helper"
require "graphql/client"
require "nxt_gql_client/query"
require "nxt_gql_client/api"

# transform_response must map aliased response keys back to canonical schema
# field names, with no-alias keys unchanged.
RSpec.describe NxtGqlClient::Query do
  let(:schema) { SpecSchemas.schema }
  let(:client) { GraphQL::Client.new(schema: schema, execute: nil) }

  # Only needed to reach the private #transform_response.
  let(:query) { described_class.allocate }

  def schema_klass_for(definition, field)
    klass = definition.schema_class
    klass = klass.of_klass until klass.respond_to?(:defined_fields)
    klass.defined_fields[field]
  end

  def transform(definition, field, data)
    query.send(:transform_response, data, schema_klass_for(definition, field))
  end

  describe "#transform_response alias handling" do
    it "maps an aliased response key back to the canonical field name" do
      definition = client.parse(<<~GQL)
        query { article { renamedTitle: title } }
      GQL

      result = transform(definition, "article", { "renamedTitle" => "Hello" })

      expect(result).to eq("title" => "Hello")
      expect(result).not_to have_key("renamed_title")
    end

    it "leaves non-aliased keys exactly as before (regression)" do
      definition = client.parse(<<~GQL)
        query { article { title author { fullName } } }
      GQL

      data = { "title" => "Hi", "author" => { "fullName" => "Jane Roe" } }
      result = transform(definition, "article", data)

      expect(result).to eq(
        "title" => "Hi",
        "author" => { "full_name" => "Jane Roe" }
      )
    end

    it "applies the canonical name to the field and still recurses into children" do
      definition = client.parse(<<~GQL)
        query { article { writer: author { name: fullName } } }
      GQL

      data = { "writer" => { "name" => "John Doe" } }
      result = transform(definition, "article", data)

      expect(result).to eq("author" => { "full_name" => "John Doe" })
    end

    it "falls back to the response key for meta fields like __typename" do
      definition = client.parse(<<~GQL)
        query {
          questions {
            id
            __typename
            ... on CheckboxQuestionChat { checkboxValue: value }
          }
        }
      GQL

      data = [{
        "__typename" => "CheckboxQuestionChat",
        "id" => "1",
        "checkboxValue" => true
      }]
      result = transform(definition, "questions", data)

      # __typename: no canonical field -> fallback to response key.
      expect(result).to eq([{
                             "__typename" => "CheckboxQuestionChat",
                             "id" => "1",
                             "value" => true
                           }])
    end

    it "maps polymorphic per-type aliases back to canonical value/view" do
      definition = client.parse(<<~GQL)
        query {
          questions {
            id
            __typename
            ... on CheckboxQuestionChat { checkboxValue: value }
            ... on SelectQuestionChat { selectValue: value selectView: view }
            ... on MultiSelectQuestionChat { multiSelectValue: value }
            ... on DateQuestionChat { dateValue: value dateView: view }
          }
        }
      GQL

      result = transform(definition, "questions", [
                           { "__typename" => "CheckboxQuestionChat", "id" => "1", "checkboxValue" => true },
                           { "__typename" => "SelectQuestionChat", "id" => "2",
                             "selectValue" => "a", "selectView" => "DROPDOWN" },
                           { "__typename" => "MultiSelectQuestionChat", "id" => "3",
                             "multiSelectValue" => %w[a b] },
                           { "__typename" => "DateQuestionChat", "id" => "4",
                             "dateValue" => "2026-05-20", "dateView" => "CALENDAR" }
                         ])
      checkbox, select, multi, date = result

      expect(checkbox).to eq("__typename" => "CheckboxQuestionChat", "id" => "1", "value" => true)
      expect(select).to eq(
        "__typename" => "SelectQuestionChat", "id" => "2",
        "value" => "a", "view" => "DROPDOWN"
      )
      expect(multi).to eq(
        "__typename" => "MultiSelectQuestionChat", "id" => "3",
        "value" => %w[a b]
      )
      expect(date).to eq(
        "__typename" => "DateQuestionChat", "id" => "4",
        "value" => "2026-05-20", "view" => "CALENDAR"
      )

      # Alias-derived names must never leak through.
      [checkbox, select, multi, date].each do |obj|
        expect(obj.keys).not_to include(
          "checkbox_value", "select_value", "multi_select_value",
          "date_value", "select_view", "date_view"
        )
      end
    end
  end

  # Round-trip: client aliases -> node_to_gql forwards -> remote answers under
  # aliases -> transform_response returns canonical names.
  describe "round-trip with node_to_gql alias preservation" do
    it "forwards client aliases and maps the remote response back to canonical names" do
      client_query = <<~GQL
        {
          questions {
            id
            ... on CheckboxQuestionChat { checkboxValue: value }
            ... on SelectQuestionChat { selectValue: value selectView: view }
          }
        }
      GQL

      # forward: rebuild the proxied query against the shared Ruby schema
      document = GraphQL::Language::Parser.parse(client_query)
      server_query = GraphQL::Query.new(schema, document: document)
      node = document.definitions.first.selections.find { |s| s.name == "questions" }
      result_class = Struct.new(:type).new(schema.types["QuestionChat"])

      rebuilt = NxtGqlClient::Model.dynamic_query_params(
        node: node, result_class: result_class, context: server_query.context
      )[:response_gql]

      expect(rebuilt).to include("checkboxValue: value")
      expect(rebuilt).to include("selectValue: value")
      expect(rebuilt).to include("selectView: view")

      # reverse: remote response keyed by those same aliases
      definition = client.parse(<<~GQL)
        query {
          questions {
            id
            __typename
            ... on CheckboxQuestionChat { checkboxValue: value }
            ... on SelectQuestionChat { selectValue: value selectView: view }
          }
        }
      GQL
      remote_response = [
        { "__typename" => "CheckboxQuestionChat", "id" => "1", "checkboxValue" => true },
        { "__typename" => "SelectQuestionChat", "id" => "2",
          "selectValue" => "x", "selectView" => "DROPDOWN" }
      ]
      mapped = transform(definition, "questions", remote_response)

      # consumer sees canonical names, not the client's aliases
      expect(mapped).to eq([
                             { "__typename" => "CheckboxQuestionChat", "id" => "1", "value" => true },
                             { "__typename" => "SelectQuestionChat", "id" => "2",
                               "value" => "x", "view" => "DROPDOWN" }
                           ])
    end
  end
end
