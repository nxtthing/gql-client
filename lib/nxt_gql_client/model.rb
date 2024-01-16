require "nxt_gql_client/api"
require "nxt_gql_client/query"
require "nxt_gql_client/results_page"
require "nxt_gql_client/invalid_response"
require "nxt_gql_client/printer"
require "nxt_gql_client/proxy_field"

module NxtGqlClient
  module Model
    extend ActiveSupport::Concern

    included do
      attr_reader :object
      delegate :[], to: :object
    end


    def initialize(response)
      @object = response
    end

    def self.field_type(field_class)
      ::Array.wrap(field_class.type).first.unwrap
    end

    private

    def association_cache(name)
      @association_cache ||= {}
      @association_cache[name] ||= yield
    end

    class_methods do
      def query(name, gql = nil, response_path = nil)
        define_singleton_method name do |resolver: nil, response_gql: nil, **args|
          return if !api.active? && !::Rails.env.production?

          definition = if block_given?
                         fragments = []
                         response_gql ||= resolver && node_to_gql(
                           node: resolver_to_node(resolver),
                           type: Model.field_type(resolver.class),
                           context: resolver.context,
                           fragments:
                         )

                         gql = [
                           yield(response_gql),
                           fragments.map do |fragment|
                             "fragment #{fragment[:name]} on #{fragment[:proxy_typename]} { #{fragment[:gql]} }"
                           end.join("\n")
                         ].compact_blank.join("\n")

                         parse_query(
                           query: gql,
                           response_path:
                         )
                       else
                         var_name = "@#{name}"
                         if instance_variable_defined?(var_name)
                           instance_variable_get(var_name)
                         else
                           instance_variable_set(var_name, parse_query(query: gql, response_path:))
                         end
                       end
          definition.call(**args)
        end

        if async?
          require "nxt_gql_client/async_query_job"
          define_singleton_method "#{name}_later" do |**args|
            AsyncQueryJob.perform_later(
              ".#{Object.const_source_location(self.name)[0].remove(::Rails.root.to_s)}",
              self.name,
              name,
              args
            )
          end
        end
      end

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
        ([self] + descendants).find { |c| c.typename == object[:__typename] }
      end

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
                                                              class_name_name_spaces[class_name_name_spaces.size - 1] = class_name
                                                              class_name_name_spaces.join("::").constantize
                                                            end
                                                          end
      end

      private

      def async?
        false
      end

      def api
        raise "gql_api_url is not specified"
      end

      def parse_query(query:, response_path:)
        definition = api.client.parse(query)
        Query.new(query_definition: definition, api:, response_path:, wrapper: self)
      end

      def resolver_to_node(resolver)
        resolver.context.query.document.definitions.each do |definition|
          definition.selections.each do |selection|
            node = selection.
              children.
              find { |child| child.name == resolver.object.field.name }.
              children.
              find { |child| child.name == resolver.field.name }
            return node if node

            node
          end
        end
      end

      def node_to_gql(node:, type:, context:, fragments:)
        return unless type.respond_to?(:fields)

        fields = node.children.map do |child|
          next if child.is_a?(GraphQL::Language::Nodes::InputObject)

          if child.is_a?(GraphQL::Language::Nodes::FragmentSpread)
            fragment_definition = context.query.fragments[child.name]
            fragment_typename = fragment_definition.type.name
            fragment_type = context.schema.types[fragment_typename]

            fragment = { name: child.name, type: fragment_type, proxy_typename: fragment_type.proxy_model.typename }
            fragments << fragment
            fragment[:gql] = node_to_gql(
              node: fragment_definition,
              type: fragment_type,
              context:,
              fragments:
            )
            next "...#{child.name}"
          end

          field = type.fields[child.name]
          next unless field

          is_proxy_field = field.is_a?(ProxyField)
          next if is_proxy_field && !field.proxy

          field_name = is_proxy_field ? field.proxy_name : field.name

          arguments = if is_proxy_field && field.proxy_attrs && child.is_a?(GraphQL::Language::Nodes::Field) && child.arguments.present?
                        Printer.new(context:, field:).print_args(child.arguments)
                      else
                        ""
                      end

          children = if (!is_proxy_field || field.proxy_children)
                       node_to_gql(node: child, type: Model.field_type(field), context:, fragments:)
                     else
                       nil
                     end
          [
            field_name.camelize(:lower),
            arguments,
            children
          ].join
        end.compact

        return if fields.empty?

        if node.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
          %( #{ fields.join("\n") } )
        else
          %( { #{ fields.join("\n") } })
        end
      end
    end
  end
end
