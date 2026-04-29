module NxtGqlClient
  class Query
    def initialize(query_definition:, api:, wrapper:, name:)
      @api = api
      @query_definition = query_definition
      @name = name.to_s
      @wrapper = wrapper
    end

    def call(context: {}, variables: {})
      transformed_variables = transform_variables(variables.deep_symbolize_keys)
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
      elsif response.is_a?(::Hash) && (response.keys - %w[nodes total]).reject { |k| k.start_with?("_") }.empty?
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
                           klass = @query_definition.schema_class
                           path = ["data"]

                           deepness = 0

                           loop do
                             klass = klass.of_klass until klass.respond_to?(:defined_fields)
                             key = klass.defined_fields.keys.first
                             path << key
                             klass = klass.defined_fields[key]
                             break if key.underscore == @name

                             deepness += 1
                             raise "Can't find #{@name} in #{deepness} level of response" if deepness > 5
                           end

                           {
                             path:,
                             klass:,
                           }
                         end
    end

    def transform_variables(data)
      @query_definition.definition_node.variables.
        select { |klass| data.key?(klass.name.underscore.to_sym) }.
        to_h { |klass| [klass.name, transform_variable(data[klass.name.underscore.to_sym], klass.type)] }
    end

    def transform_variable(data, type)
      return if data.nil?

      case type
      in GraphQL::Language::Nodes::NonNullType
        transform_variable(data, type.of_type)
      in GraphQL::Language::Nodes::TypeName
        transform_argument(data, @api.client.schema.types[type.name])
      in GraphQL::Language::Nodes::ListType
        data.map { |row| transform_variable(row, type.of_type) }
      else
        raise TypeError, "unexpected #{type.class} (#{type.inspect})"
      end
    end

    def transform_argument(data, type)
      return if data.nil?

      case type.kind.name
      when "INPUT_OBJECT"
        type.own_arguments.
          select { |name, klass| data.key?(name.underscore.to_sym) }.
          to_h { |name, klass| [name, transform_argument(data[name.underscore.to_sym], klass.type)] }
      when "NON_NULL"
        transform_argument(data, type.of_type)
      when "LIST"
        data.map { |row| transform_argument(row, type.of_type) }
      when "ENUM", "SCALAR"
        data
      else
        raise TypeError, "unexpected #{type.class} (#{type.inspect})"
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
        return if data.nil?
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
