require "graphql/client"
require "graphql/client/http"

class NxtSchedulingGql
  class InvalidResponse < StandardError
    attr_reader :response

    def initialize(message, response)
      super(message)
      @response = response
    end
  end

  class QueryCallerWrapper
    def initialize(query_definition:, response_path: nil)
      @query_definition = query_definition
      @response_path = response_path
    end

    def call(vars = {})
      variables = deep_to_h(vars).deep_transform_keys { |k| k.to_s.camelize(:lower) }
      query_result = NxtSchedulingGql.client.query(@query_definition, variables:).to_h
      raise InvalidResponse.new(query_result["errors"].first["message"], query_result) if query_result.key?("errors")

      response = response_path.reduce(query_result) { |acc, k| acc[k] }
      return response.map { |item| item.deep_transform_keys(&:underscore) } if response.is_a?(::Array)

      response && response.deep_transform_keys(&:underscore)
    end

    private

    def deep_to_h(params)
      params.transform_values do |value|
        case value
        when GraphQL::Schema::InputObject
          deep_to_h(value.to_h)
        when ::Time, ::Date
          value.iso8601
        else
          value
        end
      end
    end

    def response_path
      @response_path ||= begin
        k1 = @query_definition.schema_class.defined_fields.keys.first
        k2_class = @query_definition.schema_class.defined_fields[k1]
        k2_class = k2_class.of_klass until k2_class.respond_to?(:defined_fields)
        k2 = k2_class.defined_fields.keys.first
        ["data", k1, k2]
      end
    end
  end

  class << self
    def query(name, gql, response_path = nil)
      define_singleton_method name do |**args|
        var_name = "@#{name}"
        definition = if instance_variable_defined?(var_name)
                       instance_variable_get(var_name)
                     else
                       instance_variable_set(var_name, parse_query(query: gql, response_path:))
                     end
        definition.call(**args)
      end
    end

    def client
      @client ||= begin
                    result = ::GraphQL::Client.new(schema: schema, execute: http_client)
                    result.allow_dynamic_queries = true
                    result
                  end
    end

    private

    def http_client
      @http_client ||= ::GraphQL::Client::HTTP.new(ENV.fetch("SCHEDULING_BACK_GQL_URL"))
    end

    def schema
      @schema ||= ::GraphQL::Client.load_schema(http_client)
    end

    def parse_query(query:, response_path:)
      definition = NxtSchedulingGql.client.parse(query)
      QueryCallerWrapper.new(query_definition: definition, response_path:)
    end
  end
end
