require "nxt_gql_client/api"
require "nxt_gql_client/query"
require "nxt_gql_client/results_page"
require "nxt_gql_client/invalid_response"

module NxtGqlClient
  module Model
    extend ActiveSupport::Concern

    included do
      attr_reader :object
    end

    def initialize(response)
      @object = response.symbolize_keys
    end

    private

    def association_cache(name)
      @association_cache ||= {}
      @association_cache[name] ||= yield
    end

    class_methods do
      def query(name, gql = nil, response_path = nil)
        define_singleton_method name do |resolver: nil, response_gql: nil, **args|
          definition = if block_given?
                         response_gql ||= node_to_gql(
                           node: resolver_to_node(resolver),
                           type: ::Array.wrap(resolver.class.type).first.unwrap
                         )
                         parse_query(
                           query: yield(response_gql),
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
      end

      def attributes(*attribute_names)
        attribute_names.each do |attribute_name|
          define_method attribute_name do
            @object[attribute_name]
          end
        end
      end

      def has_many(association_name, wrapper:)
        define_method association_name do
          association_cache(association_name) do
            @object[association_name].map { |attrs| wrapper.new(attrs) }
          end
        end
      end

      def has_one(association_name, wrapper:)
        define_method association_name do
          association_cache(association_name) do
            wrapper.new(@object[association_name])
          end
        end
      end

      def gql_api_url(url = nil)
        if url
          api = Api.new(url)
          define_singleton_method :api do
            api
          end
        else
          api.url
        end
      end

      private

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

      def node_to_gql(node:, type:)
        fields = node.children.map do |child|
          next unless type.respond_to?(:fields)

          field = type.fields[child.name]
          next unless field

          field_name = field.method_sym == field.original_name ? field.name : field.method_str
          "#{ field_name.camelize(:lower) }#{ node_to_gql(node: child, type: Array.wrap(field.type).first.unwrap) }"
        end.compact

        return if fields.empty?

        %( { #{ fields.join("\n") } })
      end
    end
  end
end
