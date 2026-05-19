module NxtGqlClient
  class ResultsPage
    attr_reader :total, :nodes

    def initialize(response, &)
      @nodes = response["nodes"].map(&) if response["nodes"]
      @total = response["total"]
    end
  end
end
