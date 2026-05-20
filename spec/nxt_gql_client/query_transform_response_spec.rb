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

  def transform(definition, field, data, preserved_aliases: nil)
    q = described_class.allocate
    q.instance_variable_set(:@preserved_aliases, preserved_aliases) if preserved_aliases
    q.send(:transform_response, data, schema_klass_for(definition, field))
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

  describe "#transform_response with preserved_aliases (proxy_alias collision)" do
    # The rebuilt remote query selects `tags(filter: ...)` three times under
    # different aliases — admin-back's tags_field pattern. The client schema
    # (scheduling-tool side) only knows one `tags` field, so `canonical_field_name`
    # maps every alias back to `"tags"`. preserved_aliases is what stops the
    # three result sets from being collapsed into one bucket.
    let(:definition) do
      client.parse(<<~GQL)
        query {
          remoteAssociate {
            trainings:        tags(filter: { keys: ["associate.training"] }) { value }
            primaryFunctions: tags(filter: { keys: ["associate.primaryFunction"] }) { value }
            types:            tags(filter: { keys: ["associate.type"] }) { value }
          }
        }
      GQL
    end

    let(:remote_response) do
      {
        "trainings" => [{ "value" => "Recruiter_Academy" }],
        "primaryFunctions" => [{ "value" => "Sourcing" }],
        "types" => [{ "value" => "Internal" }]
      }
    end

    it "keeps every alias as its own key when pinned by preserved_aliases" do
      result = transform(
        definition, "remoteAssociate", remote_response,
        preserved_aliases: {
          "Associate" => Set["trainings", "primaryFunctions", "types"]
        }
      )

      # Wrapper-side `object[:trainings].pluck(:value)` must find data under
      # the underscored canonical key. snake_case-ing of the alias is
      # transform_response's job and must apply equally to pinned aliases.
      expect(result).to eq(
        "trainings" => [{ "value" => "Recruiter_Academy" }],
        "primary_functions" => [{ "value" => "Sourcing" }],
        "types" => [{ "value" => "Internal" }]
      )
    end

    it "does NOT pin an alias just because Associate elsewhere reserved the same name" do
      # End-to-end repro of the leak: node_to_gql is what produces the
      # preserved_aliases payload, so we drive it the same way the proxy
      # resolver does. The Associate subtree pins `trainings`; the questions
      # subtree happens to use the same identifier as a per-type client alias
      # that means `value`. Those two must not collide.
      client_query = <<~GQL
        {
          associate { trainings { value } }
          questions {
            id
            ... on CheckboxQuestionChat { trainings: value }
          }
        }
      GQL

      document = GraphQL::Language::Parser.parse(client_query)
      server_query = GraphQL::Query.new(schema, document: document)

      associate_node = document.definitions.first.selections.find { |s| s.name == "associate" }
      params = NxtGqlClient::Model.dynamic_query_params(
        node: associate_node,
        result_class: Struct.new(:type).new(schema.types["AssociateSchedulingTool"]),
        context: server_query.context
      )

      questions_definition = client.parse(<<~GQL)
        query {
          questions {
            id
            __typename
            ... on CheckboxQuestionChat { trainings: value }
          }
        }
      GQL

      questions_response = [
        { "__typename" => "CheckboxQuestionChat", "id" => "1", "trainings" => true }
      ]

      mapped = transform(
        questions_definition, "questions", questions_response,
        preserved_aliases: params[:preserved_aliases]
      )

      # If the pin escapes its owner type, `trainings` survives untouched
      # and `value` is missing — wrapper-side `object[:value]` would be nil.
      expect(mapped.first).to     have_key("value")
      expect(mapped.first).not_to have_key("trainings")
    end

    it "regression: without preserved_aliases the three aliases collapse onto one canonical key" do
      # This is the bug the change fixes. All three response keys
      # `trainings|primaryFunctions|types` map to the canonical field `tags`,
      # so a plain Hash#to_h collapses them — two of the three lists vanish
      # and wrapper-side `object[:trainings]` returns nil (the NoMethodError
      # `undefined method 'pluck' for nil` seen in admin-back).
      result = transform(definition, "remoteAssociate", remote_response)

      expect(result.keys).to eq(["tags"])
      # Only one bucket survives — proof of the collapse.
      expect(result["tags"]).to eq([{ "value" => "Internal" }]).or eq([{ "value" => "Sourcing" }]).
                                                                     or eq([{ "value" => "Recruiter_Academy" }])
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

    it "forwards proxy_alias-declared aliases and surfaces them as canonical wrapper keys" do
      # admin-back-shape client query: three separate fields whose proxy_alias
      # carries the literal remote selection text (tags_field pattern).
      client_query = "{ associate { trainings { value } primaryFunctions { value } types { value } } }"

      document = GraphQL::Language::Parser.parse(client_query)
      server_query = GraphQL::Query.new(schema, document: document)
      node = document.definitions.first.selections.find { |s| s.name == "associate" }
      result_class = Struct.new(:type).new(schema.types["AssociateSchedulingTool"])

      params = NxtGqlClient::Model.dynamic_query_params(
        node: node, result_class: result_class, context: server_query.context
      )

      # forward: rebuilt body inlines the proxy_alias strings as-is
      # rubocop:disable Layout/LineLength
      expect(params[:response_gql]).to include('trainings: tags(filter: { keys: ["training"] }) { value }')
      expect(params[:response_gql]).to include('primaryFunctions: tags(filter: { keys: ["primaryFunction"] }) { value }')
      expect(params[:response_gql]).to include('types: tags(filter: { keys: ["type"] }) { value }')
      # rubocop:enable Layout/LineLength

      # forward: aliases pinned under the remote (proxy_model) typename so the
      # lookup in transform_response — which sees the remote-schema typename —
      # matches. The admin-back graphql_name (`AssociateSchedulingTool`) is
      # different from the remote one (`Associate`), and pinning under it
      # would silently lose the pin on the response side.
      expect(params[:preserved_aliases]).to eq(
        "Associate" => Set["trainings", "primaryFunctions", "types"]
      )

      # reverse: a remote-shape query (single `tags` field, aliased three ways)
      # parsed against the same shared schema. This is what
      # proxy_model.parse_query sees.
      definition = client.parse(<<~GQL)
        query {
          remoteAssociate {
            trainings:        tags(filter: { keys: ["associate.training"] }) { value }
            primaryFunctions: tags(filter: { keys: ["associate.primaryFunction"] }) { value }
            types:            tags(filter: { keys: ["associate.type"] }) { value }
          }
        }
      GQL

      remote_response = {
        "trainings" => [{ "value" => "Recruiter_Academy" }],
        "primaryFunctions" => [{ "value" => "Sourcing" }],
        "types" => [{ "value" => "Internal" }]
      }

      mapped = transform(
        definition, "remoteAssociate", remote_response,
        preserved_aliases: params[:preserved_aliases]
      )

      # Wrapper-side `object[:trainings].pluck(:value)` works because every
      # alias survived the round-trip under its own (snake_cased) key.
      expect(mapped).to eq(
        "trainings" => [{ "value" => "Recruiter_Academy" }],
        "primary_functions" => [{ "value" => "Sourcing" }],
        "types" => [{ "value" => "Internal" }]
      )
    end
  end
end
