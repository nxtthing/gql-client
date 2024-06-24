module NxtGqlClient
  class Printer < ::GraphQL::Language::Printer
    def initialize(context:, field:)
      super()
      @context = context
      @field = field
    end

    def print_args(node)
      print(node).sub(/^\[(.+)\]$/, '(\1)') # replace [] backets by () brackets
    end

    private

    def print_variable_identifier(variable_identifier)
      variable_name = variable_identifier.name
      var = @context.query.instance_variable_get(:@ast_variables).find { |v| v.name == variable_name }
      type = var.type
      type = type.of_type while type.respond_to?(:of_type)
      type_name = type.name
      input_class = @context.warden.instance_variable_get(:@visible_types)[type_name]
      value = @context.query.provided_variables[variable_name]
      if input_class.respond_to?(:proxy_type)
        value = input_class.coerce_input(value, @context)
        value = input_class.proxy_type.coerce_result(value, @context)
      end
      print_string(GraphQL::Language.serialize(value))
    end

    def print_argument(argument)
      field_argument = @field.arguments[argument.name]
      name = field_argument ? field_argument.keyword.to_s.camelize(:lower) : argument.name
      print_string(argument.name)
      print_string(": ")
      print_node(argument.value)
    end
  end
end
