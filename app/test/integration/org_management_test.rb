require "test_helper"

class OrgManagementTest < ActionDispatch::IntegrationTest
  setup { @rel = build_relationship }

  test "the activity feed shows events for tags the org can see, with durable attribution" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-FEED", gross: 60_000, tare: 15_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-FEED", gross: 59_000, tare: 15_000)
    Tags::Actions.new(tag: res.tag.reload, actor: @rel.buyer_user, actor_org: @rel.buyer)
      .dispute!(reason: "Weight variance")

    @rel.buyer.memberships.find_by(user: @rel.buyer_user).end!

    sign_in_as @rel.grower_user
    get activity_index_path
    assert_response :success
    assert_match "BOL-FEED", response.body
    assert_match "Disputed", response.body
    assert_match @rel.buyer_user.display_name, response.body # still attributed after departure
  end

  test "an admin invites a colleague and promotes them; the sole-admin guard holds" do
    sign_in_as @rel.grower_user

    assert_difference -> { @rel.grower.active_memberships.count }, 1 do
      post members_path, params: { email_address: "colleague@sycamore.test", role: "member" }
    end
    membership = @rel.grower.memberships.active.joins(:user).find_by(users: { email_address: "colleague@sycamore.test" })
    assert membership.member?

    patch member_path(membership), params: { role: "admin" }
    assert membership.reload.admin?
  end

  test "the last admin cannot be demoted or removed" do
    sign_in_as @rel.grower_user
    sole = @rel.grower.memberships.active.find_by(user: @rel.grower_user)

    patch member_path(sole), params: { role: "member" }
    assert sole.reload.admin?, "sole admin stays admin"

    delete member_path(sole)
    assert sole.reload.active?, "sole admin keeps access"
  end

  test "changing a partner's tolerance from the UI re-colors open tags" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-UI", gross: 60_000, tare: 15_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-UI", gross: 59_667, tare: 15_000)
    tag = res.tag.reload
    assert tag.review?

    sign_in_as @rel.grower_user
    p = Partnership.find_by(org: @rel.grower, counterparty_org: @rel.buyer)
    patch partnership_path(p), params: { tolerance_percent: "1.0", dispute_window_days: 14 }
    assert tag.reload.matched?
  end
end
