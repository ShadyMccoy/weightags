require "test_helper"

# The headless ingest API — upload weighs and sync statuses with one simple
# "weigh tag" object. Money-adjacent path, so it's gated like the UI ingest.
class ApiWeighTagsTest < ActionDispatch::IntegrationTest
  setup do
    @rel = build_relationship
    _key, @token = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Scale house")
  end

  def auth(token = @token)
    { "Authorization" => "Bearer #{token}" }
  end

  def body
    JSON.parse(response.body)
  end

  # --- authentication -------------------------------------------------------

  test "rejects a request with no token" do
    get "/api/v1/weigh_tags"
    assert_response :unauthorized
    assert_match "API key", body["error"]
  end

  test "rejects a bad or revoked token" do
    get "/api/v1/weigh_tags", headers: auth("wt_nope")
    assert_response :unauthorized

    key, raw = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "tmp")
    key.revoke!
    get "/api/v1/weigh_tags", headers: auth(raw)
    assert_response :unauthorized
  end

  test "marks the key used on a successful request" do
    key = ApiKey.active.find_by!(org: @rel.grower)
    assert_nil key.last_used_at
    get "/api/v1/weigh_tags", headers: auth
    assert_response :success
    assert_not_nil key.reload.last_used_at
  end

  # --- upload (create) ------------------------------------------------------

  test "uploads a weigh against a named partner and pairs on BOL" do
    assert_difference -> { Weigh.count }, 1 do
      post "/api/v1/weigh_tags", headers: auth, params: {
        bol: "API-1", partner: "Pacific Hulling Co", role: "sender",
        ship_date: "2026-05-27", commodity: "Soybeans", gross: 50_000, tare: 10_000
      }
    end
    assert_response :created
    tag = body["weigh_tag"]
    assert_equal "API-1", tag["bol"]
    assert_equal "sender", tag["role"]
    assert_equal "awaiting_partner", tag["status"]
    assert_equal "40000.0", tag["mine"]["net"]
    assert_nil tag["partner_weigh"]
  end

  test "two sides auto-pair into one shared weigh tag" do
    post "/api/v1/weigh_tags", headers: auth, params: {
      bol: "API-2", partner: "Pacific Hulling Co", role: "sender", gross: 50_000, tare: 10_000
    }
    assert_response :created
    tag_id = body["weigh_tag"]["id"]

    _bk_key, buyer_token = ApiKey.issue!(org: @rel.buyer, user: @rel.buyer_user, name: "buyer")
    assert_no_difference -> { Tag.count } do
      post "/api/v1/weigh_tags", headers: auth(buyer_token), params: {
        bol: "API-2", partner: "Sycamore Ridge Farms", role: "receiver", gross: 50_010, tare: 10_000
      }
    end
    assert_response :created
    assert_equal tag_id, body["weigh_tag"]["id"]
    assert_equal "matched", body["weigh_tag"]["status"]
  end

  test "weighs in against a partner's existing tag by id, no re-keyed BOL" do
    shipment = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: "API-WI", gross: 50_000, tare: 10_000).tag

    assert_no_difference -> { Tag.count } do
      post "/api/v1/weigh_tags", headers: auth, params: {
        weigh_tag_id: shipment.id, gross: 50_005, tare: 10_000
      }
    end
    assert_response :created
    assert_equal shipment.id, body["weigh_tag"]["id"]
    assert shipment.reload.both_sided?
  end

  test "a read-only key can sync but cannot upload" do
    _ro, ro_token = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Pull", scope: :read_only)

    get "/api/v1/weigh_tags", headers: auth(ro_token)
    assert_response :success

    post "/api/v1/weigh_tags", headers: auth(ro_token), params: {
      bol: "RO-1", partner: "Pacific Hulling Co", role: "sender", gross: 1, tare: 0
    }
    assert_response :forbidden
    assert_match "read-only", body["error"]
  end

  test "rejects an upload with no partner" do
    post "/api/v1/weigh_tags", headers: auth, params: { bol: "API-3", gross: 1, tare: 0 }
    assert_response :unprocessable_entity
    assert_match "partner", body["error"]
  end

  test "surfaces validation errors as 422 with details" do
    post "/api/v1/weigh_tags", headers: auth, params: {
      partner: "Pacific Hulling Co", role: "sender", gross: 1, tare: 0
    } # missing BOL
    assert_response :unprocessable_entity
    assert(body["details"].any? { |m| m.match?(/bol/i) })
  end

  # --- sync (read) ----------------------------------------------------------

  test "lists and filters weigh tags from the caller's perspective" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "LIST-1", gross: 50_000, tare: 10_000)
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "LIST-2", gross: 30_000, tare: 5_000)

    get "/api/v1/weigh_tags", headers: auth
    assert_response :success
    assert_equal 2, body["weigh_tags"].size

    get "/api/v1/weigh_tags", headers: auth, params: { q: "LIST-1" }
    assert_equal [ "LIST-1" ], body["weigh_tags"].map { |t| t["bol"] }
  end

  test "shows a single weigh tag and 404s on one the caller can't see" do
    mine = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "SHOW-1", gross: 50_000, tare: 10_000).tag
    get "/api/v1/weigh_tags/#{mine.id}", headers: auth
    assert_response :success
    assert_equal "SHOW-1", body["weigh_tag"]["bol"]

    other = build_relationship
    theirs = post_tag(org: other.grower, counterparty: other.buyer, side: :sender,
      actor: other.grower_user, bol: "OTHER", gross: 1, tare: 0).tag
    get "/api/v1/weigh_tags/#{theirs.id}", headers: auth
    assert_response :not_found
  end
end
