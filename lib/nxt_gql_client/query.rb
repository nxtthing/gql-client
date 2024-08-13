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
      transformed_variables = transform_variables(vars, context)
      query_result = @api.client.query(@query_definition, variables: transformed_variables, context:).to_h
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

    def transform_variables(data, context)
      @query_definition.definition_node.variables.to_h do |klass|
        name = klass.name
        key = name.underscore.to_sym
        [name, transform_variable(data[key], klass.type, context)]
      end
    end

    def transform_variable(data, type, context)
      case type
      in GraphQL::Language::Nodes::NonNullType
        transform_variable(data, type.of_type, context)
      in GraphQL::Language::Nodes::TypeName
        transform_argument(data, @api.client.schema.types[type.name], context)
      else
        raise TypeError, "unexpected #{type.class} (#{type.inspect})"
      end
    end

    def transform_argument(data, type, context)
      return if data.nil?

      case type.kind.name
      when "INPUT_OBJECT"
        type.own_arguments.to_h do |name, argument_klass|
          if partitioned_argument_keys(name, data).any?
            [name, merge_partitioned_argument(name, data)]
          else
            key = name.underscore.to_sym
            [name, transform_argument(data[key], argument_klass.type, context)]
          end
        end
      when "NON_NULL"
        transform_argument(data, type.of_type, context)
      when "LIST"
        data.map { |row| transform_argument(row, type.of_type, context) }
      when "ENUM"
        data
      when "SCALAR"
        "GraphQL::Types::#{type.graphql_name}".constantize.coerce_result(data, context)
      else
        raise TypeError, "unexpected #{type.class} (#{type.inspect})"
      end
    end

    def partitioned_argument_keys(name, data)
      sub_key = name.underscore + ARRAY_ARGUMENTS_SEPARATOR
      data.keys.map(&:to_s).select { |dk| dk.starts_with?(sub_key) }
    end

    def merge_partitioned_argument(name, data)
      partitioned_keys = partitioned_argument_keys(name, data)
      result = data.to_h.slice(*partitioned_keys).values
      result.any? ? result : nil
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
