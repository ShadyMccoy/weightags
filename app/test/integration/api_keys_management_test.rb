require "test_helper"

class ApiKeysManagementTest < ActionDispatch::IntegrationTest
  setup { @rel = build_relationship }

  test "an admin creates a key, sees the token once, then revokes it" do
    sign_in_as @rel.grower_user

    assert_difference -> { ApiKey.count }, 1 do
      post api_keys_path, params: { name: "Scale house", scope: "read_only" }
    end
    follow_redirect!
    assert_match(/wt_/, response.body)  # plaintext shown once

    key = ApiKey.last
    assert key.read_only?               # scope honored
    assert_match key.public_id, response.body  # key id surfaced

    delete api_key_path(key)
    assert key.reload.revoked?
  end

  test "non-admins cannot manage keys" do
    member_user = User.create!(name: "Mem", email_address: "mem@ex.test", password: "secret123")
    Membership.create!(user: member_user, org: @rel.grower, role: :member)
    sign_in_as member_user

    get api_keys_path
    assert_redirected_to tags_path
  end
end
