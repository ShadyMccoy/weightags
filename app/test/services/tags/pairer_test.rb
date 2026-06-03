require "test_helper"

class Tags::PairerTest < ActiveSupport::TestCase
  setup { @rel = build_relationship }

  test "a single posted tag forms a one-sided pending tag visible to both orgs" do
    res = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-1", gross: 52_000, tare: 14_000)
    tag = res.tag

    assert tag.pending?
    assert tag.one_sided?
    assert_equal :receiver, tag.awaiting_side
    assert_includes Tag.for_org(@rel.grower), tag
    assert_includes Tag.for_org(@rel.buyer), tag
  end

  test "two opposing weighs on the same BOL auto-form one Tag within tolerance" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-2", gross: 52_000, tare: 14_000) # net 38000
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: "BOL-2", gross: 51_990, tare: 14_000)  # net 37990

    tag = res.tag.reload
    assert_equal 1, Tag.where(bol: "BOL-2").count
    assert tag.both_sided?
    assert tag.matched?
    assert tag.resolution_clean_match?
    assert tag.within_tolerance?
    assert_equal 38_000, tag.canonical_net
  end

  test "a net delta beyond tolerance lands the tag in review, not matched" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-3", gross: 60_000, tare: 15_000) # net 45000
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: "BOL-3", gross: 59_000, tare: 15_000)  # net 44000

    tag = res.tag.reload
    assert tag.review?
    assert tag.exceeds_tolerance?
    assert_nil tag.canonical_net
  end

  test "pairing writes a system-attributed tag.paired audit event" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-4", net: 1000)
    assert_difference -> { AuditEvent.where(action: "tag.paired").count }, 1 do
      post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
        actor: @rel.buyer_user, bol: "BOL-4", net: 1000)
    end
  end
end
