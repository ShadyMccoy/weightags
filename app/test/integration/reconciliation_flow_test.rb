require "test_helper"

class ReconciliationFlowTest < ActionDispatch::IntegrationTest
  test "self-serve signup creates a user, an org, and an admin membership" do
    assert_difference [ "User.count", "Org.count", "Membership.count" ], 1 do
      post sign_up_path, params: {
        name: "New Grower", email_address: "new@grower.test",
        org_name: "New Farms", password: "secret123"
      }
    end
    assert_redirected_to tags_path
    user = User.find_by(email_address: "new@grower.test")
    assert user.admin_of?(Org.find_by(name: "New Farms"))
  end

  test "the dashboard and detail render the shared diff and Dispute is reachable" do
    rel = build_relationship
    post_tag(org: rel.grower, counterparty: rel.buyer, side: :sender,
      actor: rel.grower_user, bol: "BOL-77", gross: 60_000, tare: 15_000)
    res = post_tag(org: rel.buyer, counterparty: rel.grower, side: :receiver,
      actor: rel.buyer_user, bol: "BOL-77", gross: 59_000, tare: 15_000)
    tag = res.tag.reload
    assert tag.review?

    sign_in_as rel.buyer_user

    get tags_path
    assert_response :success
    assert_select "h1", /Weigh tags/
    assert_match "BOL-77", response.body

    get tag_path(tag)
    assert_response :success
    assert_select "h1", /BOL-77/
    assert_match "Weigh tag comparison", response.body
    assert_match "Dispute", response.body # first-class action present
  end

  test "filing a dispute from the web transitions the tag and audits it" do
    rel = build_relationship
    post_tag(org: rel.grower, counterparty: rel.buyer, side: :sender,
      actor: rel.grower_user, bol: "BOL-88", gross: 60_000, tare: 15_000)
    res = post_tag(org: rel.buyer, counterparty: rel.grower, side: :receiver,
      actor: rel.buyer_user, bol: "BOL-88", gross: 59_000, tare: 15_000)
    tag = res.tag.reload

    sign_in_as rel.buyer_user
    assert_difference -> { AuditEvent.where(action: "tag.disputed").count }, 1 do
      post dispute_tag_path(tag), params: { reason: "Weight variance", notes: "Re-weigh requested" }
    end
    assert tag.reload.disputed?
  end

  test "editing a weigh surfaces the before/after detail in the tag activity panel" do
    rel = build_relationship
    post_tag(org: rel.grower, counterparty: rel.buyer, side: :sender,
      actor: rel.grower_user, bol: "BOL-99", gross: 60_000, tare: 15_000)
    res = post_tag(org: rel.buyer, counterparty: rel.grower, side: :receiver,
      actor: rel.buyer_user, bol: "BOL-99", gross: 59_000, tare: 15_000)
    tag = res.tag.reload

    sign_in_as rel.grower_user
    assert_difference -> { AuditEvent.where(action: "weigh.edited").count }, 1 do
      patch weigh_tag_path(tag), params: { gross: 59_000, tare: 15_000, reason: "Re-keyed off the printed ticket" }
    end

    get tag_path(tag)
    assert_response :success
    # The weigh.edited event is recorded against the Weigh, not the Tag, so it
    # must still appear in the per-tag activity panel with its change detail.
    assert_match "Weigh edited", response.body
    assert_match "Re-keyed off the printed ticket", response.body
    assert_match "45,000", response.body # before net
    assert_match "44,000", response.body # after net
  end

  test "a tag from another relationship is not reachable (org isolation)" do
    rel = build_relationship
    res = post_tag(org: rel.grower, counterparty: rel.buyer, side: :sender,
      actor: rel.grower_user, bol: "BOL-X", net: 1000)

    outsider = User.create!(name: "Outsider", email_address: "out@ex.test", password: "secret123")
    other_org = Org.create!(name: "Unrelated Co")
    Membership.create!(user: outsider, org: other_org, role: :admin)

    sign_in_as outsider
    get tag_path(res.tag)
    assert_response :not_found
  end
end
