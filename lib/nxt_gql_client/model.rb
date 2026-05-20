require "nxt_gql_client/api"
require "nxt_gql_client/query"
require "nxt_gql_client/results_page"
require "nxt_gql_client/invalid_response"
require "nxt_gql_client/printer"
require "nxt_gql_client/proxy_field"

module NxtGqlClient
  # rubocop:disable Metrics/ModuleLength
  module Model
    extend ActiveSupport::Concern

    included do
      attr_reader :object

      delegate :[], to: :object
    end

    def initialize(object)
      @object = object
    end

    class << self
      def field_type(field_class)
        ::Array.wrap(field_class.type).first.unwrap
      end

      def dynamic_query_params(node:, result_class:, context:)
        fragments = {}
        preserved_aliases = {}
        response_gql = node_to_gql(
          node:,
          type: field_type(result_class),
          context:,
          fragments:,
          preserved_aliases:
        )

        {
          response_gql:,
          fragments:,
          preserved_aliases:
        }
      end

      private

      # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def node_to_gql(node:, type:, context:, fragments:, preserved_aliases: nil)
        return unless type.respond_to?(:fields)

        # The type whose selection we're inside owns any proxy_alias pins
        # collected here. Scoping pins by owner stops `trainings` (an alias on
        # one type) from freezing a same-named client alias on a sibling type.
        # Pin under the proxy_model typename (remote-schema name): that's what
        # transform_response sees when it parses the remote response. When
        # admin-back suffixes types for cross-schema disambiguation (e.g.
        # `AssociateSchedulingTool` here vs `Associate` on the remote), the
        # local graphql_name would never match the lookup key.
        owner_typename = if type.respond_to?(:proxy_model) && type.proxy_model.respond_to?(:typename)
                           type.proxy_model.typename
                         elsif type.respond_to?(:graphql_name)
                           type.graphql_name
                         end

        # rubocop:disable Metrics/BlockLength
        fields = node.children.map do |child|
          next if child.is_a?(GraphQL::Language::Nodes::InputObject)

          if child.is_a?(GraphQL::Language::Nodes::FragmentSpread)
            name = child.name
            unless fragments[name]
              fragment_definition = context.query.fragments[name]
              fragment_typename = fragment_definition.type.name
              fragment_type = context.schema.types[fragment_typename]

              # rubocop:disable Layout/LineLength
              proxy_typename = fragment_type.respond_to?(:proxy_model) ? fragment_type.proxy_model.typename : fragment_typename
              # rubocop:enable Layout/LineLength

              fragment = { name: child.name, type: fragment_type, proxy_typename: }
              fragments[name] = fragment
              fragment[:gql] = node_to_gql(
                node: fragment_definition,
                type: fragment_type,
                context:,
                fragments:,
                preserved_aliases:
              )
            end

            next "...#{name}"
          end

          if child.is_a?(GraphQL::Language::Nodes::InlineFragment)
            fragment_typename = child.type.name
            fragment_type = context.schema.types[fragment_typename]
            proxy_typename = fragment_type.proxy_model.typename
            fragment_gql = node_to_gql(node: child, type: fragment_type, context:, fragments:, preserved_aliases:)
            next "... on #{proxy_typename} #{fragment_gql}"
          end

          field = type.fields[child.name]
          next unless field

          is_proxy_field = field.is_a?(ProxyField)
          next if is_proxy_field && !field.proxy

          field_name = is_proxy_field ? field.proxy_name : field.name

          # When a ProxyField was declared with an explicit proxy_alias, the
          # alias inside that string becomes the response key on the proxied
          # call (e.g. `trainings: tags(filter: ...)`). Pin it under the
          # owning type so the response transformer keeps it as-is instead
          # of collapsing siblings that share the underlying field name.
          # Camelize because the alias is emitted via `field_name.camelize(:lower)`
          # below, so a snake_case alias like `primary_functions:` reaches the
          # remote as `primaryFunctions:` and the response key matches that.
          if preserved_aliases && owner_typename && is_proxy_field && (alias_key = field.proxy_alias_key)
            (preserved_aliases[owner_typename] ||= Set.new) << alias_key.camelize(:lower)
          end

          # rubocop:disable Layout/LineLength
          arguments = if is_proxy_field && field.proxy_attrs && child.is_a?(GraphQL::Language::Nodes::Field) && child.arguments.present?
                        # rubocop:enable Layout/LineLength
                        Printer.new(context:).print_args(child.arguments)
                      else
                        ""
                      end

          children = if !is_proxy_field || field.proxy_children
                       node_to_gql(node: child, type: Model.field_type(field), context:, fragments:, preserved_aliases:)
                     end

          output_field_name = field_name.start_with?("_") ? field_name : field_name.camelize(:lower)

          node_alias = child.alias if child.respond_to?(:alias)
          alias_prefix = node_alias.present? && node_alias != output_field_name ? "#{node_alias}: " : ""

          [
            alias_prefix,
            output_field_name,
            arguments,
            children
          ].join
        end.compact
        # rubocop:enable Metrics/BlockLength

        if type.include?(GraphQL::Schema::Interface) && !type.ancestors.include?(GraphQL::Schema::Object)
          fields.push("__typename").uniq!
        end

        return if fields.empty?

        if node.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
          %( #{fields.join("\n")} )
        else
          %( { #{fields.join("\n")} })
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end

    private

    def association_cache(name)
      @association_cache ||= {}
      @association_cache[name] ||= yield
    end

    # rubocop:disable Metrics/BlockLength
    class_methods do
      # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
      def query(name, gql = nil, action_name = name)
        # rubocop:disable Layout/LineLength
        define_singleton_method name do |response_gql: nil, fragments: {}, preserved_aliases: nil, context: {}, variables: {}|
          # rubocop:enable Layout/LineLength
          return if !api.active? && !::Rails.env.production?

          definition = if block_given?
                         gql = [
                           yield(response_gql),
                           fragments.values.map do |fragment|
                             "fragment #{fragment[:name]} on #{fragment[:proxy_typename]} { #{fragment[:gql]} }"
                           end.join("\n")
                         ].compact_blank.join("\n")

                         parse_query(
                           query: gql,
                           action_name:,
                           preserved_aliases:
                         )
                       else
                         var_name = "@#{name}"
                         if instance_variable_defined?(var_name)
                           instance_variable_get(var_name)
                         else
                           instance_variable_set(var_name, parse_query(query: gql, action_name:))
                         end
                       end
          definition.call(context:, variables:)
        end

        return unless async?

        require "nxt_gql_client/async_query_job"
        define_singleton_method "#{name}_later" do |**variables|
          AsyncQueryJob.set(queue: async_queue).perform_later(
            ".#{Object.const_source_location(self.name)[0].remove(::Rails.root.to_s)}",
            self.name,
            name,
            variables
          )
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

      def attributes(*attribute_names)
        attribute_names.each do |attribute_name|
          define_method attribute_name do |**_args|
            @object[attribute_name]
          end
        end
      end

      def typename(value = nil)
        if value
          @typename = value
        else
          @typename ||= name.demodulize
        end
      end

      def resolve_class(object)
        typename = object[:__typename]
        return self unless typename

        @child_classes_loaded ||= begin
          file, _line = const_source_location(name)
          base_dir = File.dirname(file)
          Dir["#{base_dir}/**/*.rb"].each { |f| require f }
          true
        end

        ([self] + descendants).find { |c| c.typename == typename }
      end

      # rubocop:disable Naming/PredicatePrefix
      def has_many(association_name, class_name: nil)
        define_method association_name do |**_args|
          wrapper = self.class.association_class(association_name:, class_name:)
          association_cache(association_name) do
            @object[association_name].map { |attrs| wrapper.new(attrs) }
          end
        end
      end

      def has_one(association_name, class_name: nil)
        define_method association_name do
          wrapper = self.class.association_class(association_name:, class_name:)
          association_cache(association_name) do |**_args|
            value = @object[association_name]
            value && wrapper.new(value)
          end
        end
      end
      # rubocop:enable Naming/PredicatePrefix

      def gql_api_url(url = nil, async: false, &block)
        if url
          api = Api.new(url, &block)
          define_singleton_method :api do
            api
          end
          if async
            define_singleton_method :async? do
              true
            end
            if async.is_a?(::Hash) && async[:queue]
              define_singleton_method :async_queue do
                async[:queue]
              end
            end
          end
        else
          api.url
        end
      end

      def association_class(association_name:, class_name:)
        @association_class_per_name ||= {}
        @association_class_per_name[association_name] ||= begin
          class_name ||= association_name.to_s.singularize.camelize
          begin
            class_name.constantize
          rescue NameError
            class_name_name_spaces = name.split("::")
            class_name_name_spaces[class_name_name_spaces.size - 1] =
              class_name
            class_name_name_spaces.join("::").constantize
          end
        end
      end

      def async?
        false
      end

      def async_queue
        :default
      end

      def api
        raise "gql_api_url is not specified"
      end

      def parse_query(query:, action_name:, preserved_aliases: nil)
        definition = api.client.parse(query)
        Query.new(
          query_definition: definition,
          api:,
          action_name:,
          wrapper: self,
          preserved_aliases:
        )
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
  # rubocop:enable Metrics/ModuleLength
end
