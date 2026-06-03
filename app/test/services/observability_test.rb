require "test_helper"

class ObservabilityTest < ActiveSupport::TestCase
  setup do
    @rel = build_relationship
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-OBS", gross: 60_000, tare: 15_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-OBS", gross: 59_000, tare: 15_000)
    @tag = res.tag.reload
  end

  test "an auto-accept misfire (review tag with no sender weigh) raises an alert" do
    @tag.sender_weigh.destroy
    @tag.reload
    travel_to @tag.clock_due_at + 1.minute do
      assert_difference -> { OperationalAlert.where(kind: "auto_accept_misfire").count }, 1 do
        refute Tags::Clock.auto_accept!(@tag)
      end
    end
  end

  test "a held notification raises a delivery-failure alert without losing the inbox copy" do
    NotificationMailer.define_singleton_method(:with) { |*| raise "SMTP unavailable" }
    begin
      assert_difference -> { OperationalAlert.where(kind: "notification_delivery_failure").count }, 1 do
        assert_difference -> { Notification.where(kind: "tag.disputed").count }, 1 do
          Tags::Actions.new(tag: @tag, actor: @rel.buyer_user, actor_org: @rel.buyer)
            .dispute!(reason: "Weight variance")
        end
      end
    ensure
      NotificationMailer.singleton_class.send(:remove_method, :with)
    end
  end

  test "alerts persist their kind, message, and context" do
    alert = Alerter.raise!(kind: "clock_anomaly", message: "test", tag_id: 7)
    assert alert.persisted?
    assert_equal 7, alert.context["tag_id"]
  end
end
