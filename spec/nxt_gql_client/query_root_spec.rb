require "spec_helper"

# Smoke tests for Query-root fields that don't go through a ProxyResolver.
# The proxy round-trips (schedulingTool, chat) are covered by proxy_e2e_spec.
RSpec.describe "Admin schema Query-root fields" do
  before { SpecSchemas::Admin::Data::Article::Store.reset! }

  def run(query)
    result = SpecSchemas.schema.execute(query).to_h
    raise "schema errors: #{result['errors'].inspect}" if result["errors"]

    result["data"]
  end

  it "resolves `article` from the Article store" do
    SpecSchemas::Admin::Data::Article::Store.set_article(title: "Round-trip")

    data = run("{ article { id title author { fullName } } }")

    expect(data["article"]).to eq(
      "id" => "article-1",
      "title" => "Round-trip",
      "author" => { "fullName" => "Jane Roe" }
    )
  end

  it "resolves `remoteAssociate` straight from the scheduling-tool store" do
    SpecSchemas::SchedulingTool::Data::Associate::Store.reset!
    SpecSchemas::SchedulingTool::Data::Associate::Store.add_associate

    data = run('{ remoteAssociate { id tags(filter: { keys: ["training"] }) { value } } }')

    expect(data["remoteAssociate"]).to eq(
      "id" => "assoc-1",
      "tags" => [{ "value" => "Recruiter_Academy" }]
    )
  end
end
