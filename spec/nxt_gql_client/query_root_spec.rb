require "spec_helper"

# Smoke tests for Query-root fields that don't go through a ProxyResolver.
# The proxy round-trips (schedulingTool, chat) are covered by proxy_e2e_spec.
RSpec.describe "Admin schema Query-root fields" do
  def run(query)
    result = SpecSchemas.admin_schema.execute(query).to_h
    raise "schema errors: #{result['errors'].inspect}" if result["errors"]

    result["data"]
  end

  it "resolves `article` from the inline scaffold" do
    data = run("{ article { id title author { fullName } } }")

    expect(data["article"]).to eq(
      "id" => "article-1",
      "title" => "Hello",
      "author" => { "fullName" => "Jane Roe" }
    )
  end

  it "resolves `remoteAssociate` straight from the scheduling store" do
    SpecSchemas::Scheduling::Data::Associate::Store.reset!
    SpecSchemas::Scheduling::Data::Associate::Store.add_associate

    data = run('{ remoteAssociate { id tags(filter: { keys: ["training"] }) { key value } } }')

    expect(data["remoteAssociate"]).to eq(
      "id" => "assoc-1",
      "tags" => [{ "key" => "training", "value" => "Recruiter_Academy" }]
    )
  end
end
