module NxtGqlClient
  class Query
    def initialize(query_definition:, api:, wrapper:, action_name:, preserved_aliases: nil)
      @api = api
      @query_definition = query_definition
      @action_name = action_name.to_s
      @wrapper = wrapper
      @preserved_aliases = preserved_aliases
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
          break if key.underscore == @action_name

          deepness += 1
          raise "Can't find #{@action_name} in #{deepness} level of response" if deepness > 5
        end

        {
          path:,
          klass:
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

    # rubocop:disable Metrics/CyclomaticComplexity
    def transform_argument(data, type)
      return if data.nil?

      case type.kind.name
        when "INPUT_OBJECT"
          type.own_arguments.
            select { |name, _klass| data.key?(name.underscore.to_sym) }.
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
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/DuplicateBranch
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

          owner_typename = klass.klass.type.graphql_name if klass.klass.type.respond_to?(:graphql_name)
          alias_to_field = owner_typename && @preserved_aliases ? @preserved_aliases[owner_typename] : nil

          data.to_h do |k, v|
            # `k` is the response key (alias). If the owning type mapped this
            # alias to a client-side field name (proxy_alias case), rewrite
            # to that — sibling aliases that share an underlying remote field
            # would otherwise collapse onto one canonical key. Pins are
            # scoped by owner so a `trainings` alias on one type can't bleed
            # into a same-named client alias on a sibling type. Field-type
            # lookup still goes by `k`.
            result_key = alias_to_field&.dig(k) || canonical_field_name(klass, k) || k
            [result_key.underscore, transform_response(v, klass.defined_fields[k])]
          end
        else
          raise TypeError, "unexpected #{klass.class} (#{klass.inspect})"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/DuplicateBranch

    # Response key (alias) -> canonical schema field name, or nil for
    # meta fields like __typename (caller falls back to the response key).
    def canonical_field_name(klass, response_key)
      @canonical_field_names ||= {}.compare_by_identity
      map = @canonical_field_names[klass] ||= build_canonical_field_names(klass)
      map[response_key]
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def build_canonical_field_names(klass)
      gql_type = klass.klass.type
      return {} unless gql_type.respond_to?(:get_field)

      document = klass.definition.document
      null_context = if GraphQL::Query::NullContext.respond_to?(:instance)
                       GraphQL::Query::NullContext.instance
                     else
                       GraphQL::Query::NullContext
                     end

      # Walk every selection set. Within one selection set, if the same
      # schema field is selected more than once (necessarily under different
      # aliases, with different arguments), each alias has to stay as its
      # own canonical key — collapsing onto the schema name would merge the
      # response buckets and silently lose data. Single-use aliases still
      # collapse, which is what callers expect (`renamedTitle: title` -> `title`).
      # Scoping the collision check to one selection set keeps unrelated
      # subtrees (e.g. per-type inline fragments under an interface)
      # independent.
      mapping = {}
      visit = lambda do |node|
        if node.respond_to?(:selections)
          # First pass: tally how many times each schema field is selected in
          # this set so the second pass can decide collapse vs. preserve.
          # The two passes must stay separate — collapsing them changes the
          # tally semantics (each child would see itself counted only once
          # at decision time).
          names_in_set = Hash.new(0)
          node.selections.each do |child|
            names_in_set[child.name] += 1 if child.is_a?(GraphQL::Language::Nodes::Field)
          end
          # rubocop:disable Style/CombinableLoops
          node.selections.each do |child|
            next unless child.is_a?(GraphQL::Language::Nodes::Field)

            response_key = child.alias || child.name
            next if mapping.key?(response_key)
            next unless gql_type.get_field(child.name, null_context)

            collapse = child.alias.nil? || names_in_set[child.name] < 2
            mapping[response_key] = collapse ? child.name : response_key
          end
          # rubocop:enable Style/CombinableLoops
        end
        node.children.each { |child| visit.call(child) } if node.respond_to?(:children)
      end
      document.definitions.each { |definition| visit.call(definition) }
      mapping
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
