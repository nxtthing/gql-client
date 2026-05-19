Gem::Specification.new do |s|
  s.name        = "nxt_gql_client"
  s.summary     = "NxtGqlClient"
  s.version     = "0.6.21"
  s.authors     = ["Aliaksandr Yakubenka"]
  s.email       = "alexandr.yakubenko@startdatelabs.com"
  s.files       = ["lib/nxt_gql_client.rb"]
  s.license     = "MIT"
  s.required_ruby_version = ">= 3.2"
  s.add_dependency "activesupport"
  s.add_dependency "graphql-client"
  s.metadata["rubygems_mfa_required"] = "true"
end
