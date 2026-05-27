module SpecSchemas
  # Adapter that lets a GraphQL::Client run against an in-process schema
  # instead of HTTP. GraphQL::Client calls `#execute` with a parsed document;
  # we hand the query string to the schema's own executor and return its
  # result hash unchanged. This is a transport bridge only — it stubs no
  # data, the schema resolves everything itself.
  class LocalSchemaExecute
    def initialize(schema)
      @schema = schema
    end

    def execute(document:, operation_name: nil, variables: {}, context: {})
      @schema.execute(
        document.to_query_string,
        operation_name: operation_name,
        variables: variables,
        context: context
      ).to_h
    end
  end
end
