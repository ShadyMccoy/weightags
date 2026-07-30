require "test_helper"

# The headless ingest API — upload weighs and sync statuses with one simple
# "weigh tag" object. Money-adjacent path, so it's gated like the UI ingest.
class ApiWeighTagsTest < ActionDispatch::IntegrationTest
  setup do
    @rel = build_relationship
    _key, @token = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Scale house", scope: :read_write)
    # Throttle buckets are process-local and outlive a single test, so start clean.
    Api::V1::BaseController::THROTTLE_STORE.clear
  end

  def auth(token = @token)
    { "Authorization" => "Bearer #{token}" }
  end

  def body
    JSON.parse(response.body)
  end

  # Rails' request lines, the log subscriber, and an API controller each reach for
  # a different logger holder, so all three get swapped.
  LOGGER_HOLDERS = [ Rails, ActionController::Base, ActionController::API ].freeze

  def capture_log
    sink = StringIO.new
    replacement = ActiveSupport::Logger.new(sink)
    originals = LOGGER_HOLDERS.map(&:logger)
    LOGGER_HOLDERS.each { |holder| holder.logger = replacement }
    yield
    sink.string
  ensure
    LOGGER_HOLDERS.zip(originals).each { |holder, logger| holder.logger = logger }
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

  test "never reveals whether a rejected token is unknown or revoked" do
    key, revoked = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "old")
    key.revoke!

    get "/api/v1/weigh_tags", headers: auth(revoked)
    revoked_body = response.body
    get "/api/v1/weigh_tags", headers: auth("wt_live_neverexisted")
    assert_equal revoked_body, response.body
  end

  test "throttles per key, not per IP, and says when to retry" do
    base = Api::V1::BaseController
    key = ApiKey.active.find_by!(org: @rel.grower)

    # Walk the bucket to the ceiling rather than making 600 real requests; the
    # next one is the request that crosses it.
    base::THROTTLE_STORE.write(base.throttle_bucket(:key, key.public_id),
      base::RATE_LIMIT, expires_in: base::RATE_WINDOW)

    get "/api/v1/weigh_tags", headers: auth
    assert_response :too_many_requests
    assert_match "Too many requests", body["error"]
    assert_equal base::RATE_WINDOW.to_i.to_s, response.headers["Retry-After"]

    # Same IP, different key: unaffected — integrations share egress addresses.
    _other, other_token = ApiKey.issue!(org: @rel.buyer, user: @rel.buyer_user, name: "buyer", scope: :read_write)
    get "/api/v1/weigh_tags", headers: auth(other_token)
    assert_response :success
  end

  # A leaked log is a leaked credential if the token is in it. The key id is the
  # identifier that belongs in logs and support tickets.
  test "logs the key id and never the token" do
    written = capture_log { get "/api/v1/weigh_tags", headers: auth }

    assert_response :success
    assert_includes written, ApiKey.active.find_by!(org: @rel.grower).public_id
    assert_not_includes written, @token
  end

  test "the throttle counts requests, so an unthrottled key stays under" do
    3.times { get "/api/v1/weigh_tags", headers: auth }
    assert_response :success
  end

  test "stops answering an IP that keeps presenting bad tokens" do
    base = Api::V1::BaseController
    base::THROTTLE_STORE.write(base.throttle_bucket(:auth_failure, "127.0.0.1"),
      base::AUTH_FAILURE_LIMIT - 1, expires_in: base::AUTH_FAILURE_WINDOW)

    get "/api/v1/weigh_tags", headers: auth("wt_live_wrong")
    assert_response :unauthorized

    get "/api/v1/weigh_tags", headers: auth("wt_live_wrong")
    assert_response :too_many_requests
    assert_equal base::AUTH_FAILURE_WINDOW.to_i.to_s, response.headers["Retry-After"]

    # A good key is not collateral damage — the cap is on failures.
    get "/api/v1/weigh_tags", headers: auth
    assert_response :success
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

    _bk_key, buyer_token = ApiKey.issue!(org: @rel.buyer, user: @rel.buyer_user, name: "buyer", scope: :read_write)
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

  # The read path 404s across orgs; the write path has to as well, or a key could
  # append a weigh to a shipment its org is not a party to.
  test "a key cannot weigh in against another org's shipment" do
    other = build_relationship
    theirs = post_tag(org: other.grower, counterparty: other.buyer, side: :sender,
      actor: other.grower_user, bol: "NOT-MINE", gross: 50_000, tare: 10_000).tag

    assert_no_difference -> { Weigh.count } do
      post "/api/v1/weigh_tags", headers: auth, params: {
        weigh_tag_id: theirs.id, gross: 50_005, tare: 10_000
      }
    end
    assert_response :not_found
  end

  test "a key cannot post as, or read, another org" do
    _other_key, other_token = ApiKey.issue!(org: @rel.buyer, user: @rel.buyer_user, name: "buyer", scope: :read_write)
    post "/api/v1/weigh_tags", headers: auth, params: {
      bol: "OWN-1", partner: "Pacific Hulling Co", role: "sender", gross: 50_000, tare: 10_000
    }
    assert_response :created
    tag_id = body["weigh_tag"]["id"]

    # The buyer is a party to that shipment, so it is visible to them — but from
    # their own side, and the weigh stays owned by the grower.
    get "/api/v1/weigh_tags/#{tag_id}", headers: auth(other_token)
    assert_response :success
    assert_equal "receiver", body["weigh_tag"]["role"]
    assert_nil body["weigh_tag"]["mine"]

    # A third org, party to nothing here, sees nothing.
    stranger = build_relationship
    _sk, stranger_token = ApiKey.issue!(org: stranger.grower, user: stranger.grower_user, name: "s")
    get "/api/v1/weigh_tags/#{tag_id}", headers: auth(stranger_token)
    assert_response :not_found
    get "/api/v1/weigh_tags", headers: auth(stranger_token)
    assert_empty body["weigh_tags"]
  end
end
