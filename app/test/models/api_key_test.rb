require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  setup do
    @rel = build_relationship
  end

  test "issue! returns the plaintext once and stores only the digest" do
    key, raw = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Tablet")
    assert raw.start_with?("wt_")
    assert_not_equal raw, key.token_digest
    assert_equal ApiKey.digest(raw), key.token_digest
    assert_equal raw.last(4), key.token_last4
  end

  test "issue! assigns a non-secret key id and defaults to read-write" do
    key, = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Tablet")
    assert key.public_id.start_with?("wtk_")
    assert key.read_write?
    assert key.can_write?

    ro, = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "Pull", scope: :read_only)
    assert ro.read_only?
    assert_not ro.can_write?
  end

  test "authenticate resolves a live token and ignores revoked ones" do
    key, raw = ApiKey.issue!(org: @rel.grower, user: @rel.grower_user, name: "k")
    assert_equal key, ApiKey.authenticate(raw)

    key.revoke!
    assert_nil ApiKey.authenticate(raw)
    assert_nil ApiKey.authenticate("wt_bogus")
    assert_nil ApiKey.authenticate(nil)
  end
end
