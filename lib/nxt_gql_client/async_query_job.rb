module NxtGqlClient
  class AsyncQueryJob < ::ActiveJob::Base
    def perform(model_path, model_name, query_name, params)
      require model_path
      model_name.constantize.send(query_name, params)
    end
  end
end
