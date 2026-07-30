require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  setup do
    @rel = build_relationship
  end

  test "issue! returns the plaintext once and stores only the digest" do
    key, raw = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Tablet")
    assert raw.start_with?("wt_live_")
    assert_operator raw.length, :>=, 50   # prefix + 43 random chars
    assert_not_equal raw, key.token_digest
    assert_equal ApiKey.digest(raw), key.token_digest
  end

  # The whole point of digest-only storage: a database dump leaks nothing usable.
  test "the plaintext token is nowhere in the api_keys row" do
    _key, raw = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Tablet")
    secret = raw.delete_prefix(ApiKey::PREFIX)
    stored = ApiKey.connection.select_one("SELECT * FROM api_keys ORDER BY id DESC LIMIT 1")

    stored.each_value do |value|
      assert_not_includes value.to_s, secret, "a column still holds the plaintext"
    end
    # Not even a fragment: a suffix column was removed deliberately.
    assert_not_includes ApiKey.column_names, "token_last4"
  end

  test "two keys never collide" do
    _a, raw_a = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "a")
    _b, raw_b = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "b")
    assert_not_equal raw_a, raw_b
  end

  test "issue! assigns a non-secret key id and defaults to the weaker scope" do
    key, = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Tablet")
    assert key.public_id.start_with?("wtk_")
    assert key.read_only?
    assert_not key.can_write?

    rw, = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Scale", scope: :read_write)
    assert rw.read_write?
    assert rw.can_write?
  end

  # Fail closed at the storage layer too, not just in the controller.
  test "a row created with no scope at all is read-only" do
    key = ApiKey.create!(org: @rel.grower, user: @rel.grower_user, name: "Bare",
      public_id: "wtk_bare", token_digest: ApiKey.digest("wt_live_bare"))
    assert key.read_only?
    assert_equal "read_only", ApiKey.columns_hash["scope"].default
  end

  test "authenticate resolves a live token and ignores revoked ones" do
    key, raw = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "k")
    assert_equal key, ApiKey.authenticate(raw)

    key.revoke!
    assert_nil ApiKey.authenticate(raw)
    assert_nil ApiKey.authenticate("wt_bogus")
    assert_nil ApiKey.authenticate(nil)
  end

  test "mark_used! debounces so a polling integration isn't a write per read" do
    key, = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Poller")

    key.mark_used!
    first = key.reload.last_used_at
    assert_not_nil first

    key.mark_used!
    assert_equal first, key.reload.last_used_at, "should not rewrite within the window"

    key.update_column(:last_used_at, (ApiKey::USED_AT_RESOLUTION + 1.second).ago)
    key.mark_used!
    assert_operator key.reload.last_used_at, :>, first
  end
end
