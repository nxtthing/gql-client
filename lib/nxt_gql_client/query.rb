module NxtGqlClient
  class Query
    def initialize(query_definition:, api:, wrapper:, response_path: nil)
      @api = api
      @query_definition = query_definition
      @response_path = response_path
      @wrapper = wrapper
    end

    def call(vars = {})
      variables = deep_to_h(vars).deep_transform_keys { |k| k.to_s.camelize(:lower) }
      query_result = @api.client.query(@query_definition, variables:).to_h
      raise InvalidResponse.new(query_result["errors"].first["message"], query_result) if query_result.key?("errors")

      response = response_path.reduce(query_result) { |acc, k| acc[k] }
      return response.map { |item| item.deep_transform_keys(&:underscore) } if response.is_a?(::Array)
      return response if response.is_a?(::TrueClass) or response.is_a?(::FalseClass)

      response && result(response.deep_transform_keys(&:underscore))
    end

    private

    def result(response)
      if (response.keys - ["nodes", "total"]).empty?
        ResultsPage.new(response) do |node_response|
          @wrapper.new(node_response)
        end
      else
        @wrapper.new(response)
      end
    end

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
end
