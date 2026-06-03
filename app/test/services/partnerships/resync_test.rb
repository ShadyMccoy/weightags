require "test_helper"

class Partnerships::ResyncTest < ActiveSupport::TestCase
  setup do
    @rel = build_relationship
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-T", gross: 60_000, tare: 15_000) # 45000
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-T", gross: 59_667, tare: 15_000) # 44667 -> -0.74%
    @tag = res.tag.reload
    assert @tag.review?
  end

  def grower_partnership
    Partnership.find_by(org: @rel.grower, counterparty_org: @rel.buyer)
  end

  test "loosening tolerance re-colors an open tag to matched and clears the clock" do
    p = grower_partnership
    p.update!(tolerance_bps: 100) # 1%
    Partnerships::Resync.call(p)

    @tag.reload
    assert @tag.matched?
    assert_nil @tag.clock_due_at
    assert_equal 100, @tag.tolerance_bps
  end

  test "shortening the dispute window retargets the running clock" do
    p = grower_partnership
    started = @tag.clock_started_at
    p.update!(dispute_window_days: 3)
    Partnerships::Resync.call(p)

    @tag.reload
    assert @tag.review?
    assert_in_delta (started + 3.days).to_f, @tag.clock_due_at.to_f, 5
  end

  test "closed history is left untouched" do
    Tags::Actions.new(tag: @tag, actor: @rel.grower_user, actor_org: @rel.grower).accept!
    assert @tag.reload.resolved?

    p = grower_partnership
    p.update!(tolerance_bps: 100)
    Partnerships::Resync.call(p)
    assert @tag.reload.resolved?, "a resolved tag is settled history"
  end
end
