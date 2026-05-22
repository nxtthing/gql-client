require "active_support/all"
require "graphql"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
# RSpec already puts the spec dir on $LOAD_PATH; make it explicit so the
# `support/...` requires below (and in the type files) resolve regardless
# of how the suite is invoked.
$LOAD_PATH.unshift __dir__ unless $LOAD_PATH.include?(__dir__)

require "nxt_gql_client/model"
require "nxt_gql_client/proxy_field"

# Spec support files require each other via "support/..." paths; loading
# the schema facade pulls in the whole type graph in dependency order.
require "support/schemas"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
