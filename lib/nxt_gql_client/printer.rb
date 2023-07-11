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
      @context.query.provided_variables[variable_identifier.name].to_json
    end

    def print_argument(argument)
      field_argument = @field.arguments[argument.name]
      name = field_argument ? field_argument.keyword.to_s.camelize(:lower) : argument.name
      "#{name}: #{print(argument.value)}"
    end
  end
end
