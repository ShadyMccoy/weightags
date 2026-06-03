require "test_helper"

class NotificationsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup { @rel = build_relationship }

  test "posting a tag notifies the counterparty in the inbox and by email" do
    assert_difference -> { Notification.where(kind: "weigh.posted").count }, 1 do
      assert_enqueued_emails 1 do
        post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
          actor: @rel.grower_user, bol: "BOL-N", net: 1000)
      end
    end
    n = Notification.where(kind: "weigh.posted").last
    assert_equal @rel.buyer_user, n.user
    assert_equal @rel.buyer, n.org
    assert AuditEvent.exists?(action: "weigh.posted", bol: "BOL-N")
  end

  test "a dispute notifies the other party in their inbox" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-D", gross: 60_000, tare: 15_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-D", gross: 59_000, tare: 15_000)
    assert_difference -> { Notification.where(kind: "tag.disputed", user: @rel.grower_user).count }, 1 do
      Tags::Actions.new(tag: res.tag.reload, actor: @rel.buyer_user, actor_org: @rel.buyer)
        .dispute!(reason: "Weight variance")
    end
  end

  test "the inbox lists notifications and marks them read" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-INBOX", net: 1000)
    n = Notification.where(user: @rel.buyer_user).last

    sign_in_as @rel.buyer_user
    get notifications_path
    assert_response :success
    assert_match "BOL-INBOX", response.body

    patch notification_path(n)
    assert n.reload.read?
  end
end
