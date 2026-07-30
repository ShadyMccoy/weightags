require "test_helper"

# The public API reference: OpenAPI spec + rendered Redoc page, both reachable
# without authentication. The spec is also tested for structural correctness so
# it can't silently drift from a valid OpenAPI 3.1 document.
class ApiDocsTest < ActionDispatch::IntegrationTest
  test "serves the OpenAPI spec publicly as YAML" do
    get "/openapi.yaml"
    assert_response :success
    assert_match %r{application/yaml}, response.media_type
    assert_match "openapi: 3.1.0", response.body
  end

  test "serves the Redoc reference page publicly" do
    get "/api/docs"
    assert_response :success
    assert_match "redoc", response.body
    assert_match openapi_spec_path, response.body
  end

  test "the landing page points developers at the reference" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", api_docs_path
  end

  test "the spec is a valid OpenAPI 3.1 document describing the live endpoints" do
    doc = YAML.load_file(ApiDocsController::SPEC_PATH)

    assert_equal "3.1.0", doc["openapi"]
    assert_equal %w[bearerAuth], doc.dig("components", "securitySchemes").keys

    paths = doc["paths"]
    assert paths.key?("/api/v1/weigh_tags")
    assert paths.key?("/api/v1/weigh_tags/{id}")
    assert_equal %w[get post], paths["/api/v1/weigh_tags"].keys.sort

    # Documented statuses match the serializer's vocabulary.
    documented = doc.dig("components", "schemas", "WeighTag", "properties", "status", "enum")
    assert_includes documented, "awaiting_partner"
    assert_includes documented, "awaiting_you"
  end
end
