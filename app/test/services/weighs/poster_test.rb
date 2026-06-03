require "test_helper"

class Weighs::PosterTest < ActiveSupport::TestCase
  setup { @rel = build_relationship }

  test "weighing in against the partner's tag shares identity — no new tag, no typo" do
    shipment = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-WI", gross: 50_000, tare: 10_000).tag
    assert shipment.pending?

    assert_no_difference -> { Tag.count } do
      result = Weighs::Poster.call(org: @rel.buyer, actor: @rel.buyer_user,
        attributes: { gross: 50_010, tare: 10_000 }, into: shipment)
      assert result.ok?
      assert_equal shipment.id, result.tag.id
      assert_equal "receiver", result.weigh.side          # derived from the tag
      assert_equal @rel.grower, result.weigh.counterparty_org
      assert_equal "BOL-WI", result.weigh.bol             # adopted the shared reference
    end

    assert shipment.reload.matched?, "both weighs present and within tolerance"
    assert_equal 2, shipment.weighs.count
  end

  test "weigh-in does not raise a fuzzy suggestion (identity is already shared)" do
    shipment = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-WI2", gross: 50_000, tare: 10_000).tag
    assert_no_difference -> { PairingSuggestion.count } do
      Weighs::Poster.call(org: @rel.buyer, actor: @rel.buyer_user,
        attributes: { gross: 99_999, tare: 10_000 }, into: shipment) # wild value, still no suggestion
    end
  end

  test "recorded_ref is the weigh's own keyed reference" do
    result = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "REF-001", net: 1000)
    assert_equal "REF-001", result.weigh.recorded_ref
  end
end
