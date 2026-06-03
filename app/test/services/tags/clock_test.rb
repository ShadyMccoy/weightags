require "test_helper"

class Tags::ClockTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @rel = build_relationship
    @tag = build_review_load
  end

  def build_review_load(bol: "BOL-CLK")
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: bol, gross: 60_000, tare: 15_000) # sender net 45000
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: bol, gross: 59_000, tare: 15_000)    # receiver net 44000
    res.tag.reload
  end

  test "the clock starts when both sides post a tag that needs review" do
    assert @tag.review?
    assert @tag.clock_started_at.present?
    assert_in_delta 14.days.from_now.to_f, @tag.clock_due_at.to_f, 5
  end

  test "a within-tolerance match never starts a clock" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-OK", gross: 52_000, tare: 14_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: "BOL-OK", gross: 51_990, tare: 14_000)
    tag = res.tag.reload
    assert tag.matched?
    assert_nil tag.clock_due_at
  end

  test "auto-accept fires at T+N to the sender's values and is idempotent" do
    sender_net = @tag.sender_weigh.net

    travel_to @tag.clock_due_at + 1.minute do
      assert_difference -> { AuditEvent.where(action: "tag.auto_accepted").count }, 1 do
        assert_equal 1, Tags::Clock.process_due[:auto_accepted]
      end
      assert_equal 0, Tags::Clock.process_due[:auto_accepted]
    end

    @tag.reload
    assert @tag.resolved?
    assert @tag.resolution_auto_accepted?
    assert_equal sender_net, @tag.canonical_net
    assert_nil @tag.resolved_by, "auto-accept is a system action, not a user"
    assert_nil @tag.clock_due_at
  end

  test "auto-accept does NOT fire before the window closes" do
    travel_to @tag.clock_due_at - 1.hour do
      assert_equal 0, Tags::Clock.process_due[:auto_accepted]
    end
    assert @tag.reload.review?
  end

  test "a dispute pauses the clock so auto-accept never fires" do
    Tags::Actions.new(tag: @tag, actor: @rel.buyer_user, actor_org: @rel.buyer)
      .dispute!(reason: "Weight variance")
    assert_nil @tag.reload.clock_due_at

    travel_to 30.days.from_now do
      assert_equal 0, Tags::Clock.process_due[:auto_accepted]
    end
    assert @tag.reload.disputed?
  end

  test "reminders deliver once at the half and final marks, and email both parties" do
    travel_to @tag.clock_due_at - 6.days do
      assert_difference -> { AuditEvent.where(action: "tag.reminder_sent").count }, 1 do
        assert_emails 1 do
          perform_enqueued_jobs { Tags::Clock.process_due }
        end
      end
      assert_equal 0, Tags::Clock.process_due[:reminded], "no duplicate half reminder"
    end
    assert_equal "half", AuditEvent.where(action: "tag.reminder_sent").last.metadata["mark"]

    travel_to @tag.clock_due_at - 12.hours do
      assert_difference -> { AuditEvent.where(action: "tag.reminder_sent").count }, 1 do
        Tags::Clock.process_due
      end
    end
    assert_equal "final", AuditEvent.where(action: "tag.reminder_sent").last.metadata["mark"]
  end

  test "the recurring job delegates to the sweep" do
    travel_to @tag.clock_due_at + 1.minute do
      DisputeClockJob.perform_now
    end
    assert @tag.reload.resolution_auto_accepted?
  end
end
