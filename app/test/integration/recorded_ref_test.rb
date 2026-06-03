require "test_helper"

class RecordedRefTest < ActionDispatch::IntegrationTest
  setup do
    @rel = build_relationship
    @target = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "10849", gross: 50_000, tare: 10_000).tag
    source = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: "1O849", gross: 50_010, tare: 10_000).tag
    Tags::Merge.merge!(source: source, target: @target, actor: @rel.buyer_user, actor_org: @rel.buyer)
  end

  test "the merged shipment shows each side's recorded reference when they differ" do
    sign_in_as @rel.grower_user
    get tag_path(@target)
    assert_response :success
    assert_match "Recorded ref", response.body
    assert_match "1O849", response.body   # the receiver's keyed reference, preserved
  end
end
