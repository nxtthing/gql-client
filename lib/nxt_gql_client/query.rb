module NxtGqlClient
  class Query
    ARRAY_ARGUMENTS_SEPARATOR = "_part_".freeze

    def initialize(query_definition:, api:, wrapper:, response_path: nil)
      @api = api
      @query_definition = query_definition
      @response_path = response_path
      @wrapper = wrapper
    end

    def call(context: {}, **vars)
      variables = deep_to_h(vars).deep_transform_keys { |k| k.to_s.camelize(:lower) }
      query_result = @api.client.query(@query_definition, variables:, context:).to_h
      raise InvalidResponse.new(query_result["errors"].first["message"], query_result) if query_result.key?("errors")

      response = response_meta[:path].reduce(query_result) { |acc, k| acc[k] }
      transformed_response = transform_response(
        response,
        response_meta[:klass]
      )
      result(transformed_response)
    end

    private

    def result(response)
      if response.is_a?(::Array)
        response.map { |item| wrap(item) }
      elsif response.is_a?(::Hash) && (response.keys - %w[nodes total]).empty?
        ResultsPage.new(response) do |node_response|
          wrap(node_response)
        end
      else
        wrap(response)
      end
    end

    def wrap(response)
      return response unless response.is_a?(::Hash)

      object = response.deep_symbolize_keys
      @wrapper.resolve_class(object).new(object)
    end

    def deep_to_h(value)
      case value
      when GraphQL::Schema::InputObject, Hash
        merge_array_arguments(value.to_h).transform_values { |v| deep_to_h(v) }
      when ::Array
        value.map { |v| deep_to_h(v) }
      when ::Time, ::Date
        value.iso8601
      else
        value
      end
    end

    def merge_array_arguments(args)
      keys = args.keys
      keys_to_merge, rest_keys = keys.partition { |k| k.to_s.include?(ARRAY_ARGUMENTS_SEPARATOR) }
      grouped_keys_to_merge = keys_to_merge.group_by { |k| k.to_s.split(ARRAY_ARGUMENTS_SEPARATOR).first }
      merged_args = grouped_keys_to_merge.to_a.each_with_object({}) do |(base_key, keys), result|
        result[base_key] = args.slice(*keys).values
      end
      args.slice(*rest_keys).merge(merged_args)
    end

    # TODO[SL]: unstable. suggest to require "payload" definition.
    def response_meta
      @response_meta ||= begin
                           k1 = @query_definition.schema_class.defined_fields.keys.first
                           k2_class = @query_definition.schema_class.defined_fields[k1]
                           k2_class = k2_class.of_klass until k2_class.respond_to?(:defined_fields)
                           k2 = k2_class.defined_fields.keys.first
                           k3_class = k2_class.defined_fields[k2]

                           {
                             path: ["data", k1, k2],
                             klass: k3_class,
                           }
                         end
    end

    def transform_response(data, klass)
      case klass
      in GraphQL::Client::Schema::ScalarType
        data
      in GraphQL::Client::Schema::EnumType
        data
      in GraphQL::Client::Schema::ListType
        data&.map { |row| transform_response(row, klass.of_klass) }
      in GraphQL::Client::Schema::NonNullType
        transform_response(data, klass.of_klass)
      in GraphQL::Client::Schema::PossibleTypes
        typename = data["__typename"]
        k_klass = klass.possible_types[typename]
        transform_response(data, k_klass)
      in GraphQL::Client::Schema::ObjectType::WithDefinition
        return if data.nil?

        data.to_h do |k,v|
          [k.underscore, transform_response(v, klass.defined_fields[k])]
        end
      else
        raise TypeError, "unexpected #{klass.class} (#{klass.inspect})"
      end
    end
  end
end
