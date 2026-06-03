require "test_helper"
require "view_component/test_helpers"
require "view_component/test_case"

class DeltaCellComponentTest < ViewComponent::TestCase
  setup { @rel = build_relationship }

  def both_sided_load(sender_net_gross, receiver_net_gross)
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-DC#{SecureRandom.hex(2)}", gross: sender_net_gross, tare: 0)
    post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: Weigh.last(2).first.bol, gross: receiver_net_gross, tare: 0).tag.reload
  end

  test "within tolerance renders green with a signed percentage" do
    tag = both_sided_load(50_000, 50_010) # +0.02%
    render_inline(DeltaCellComponent.new(tag: tag, metric: :net, show_pct: true))
    assert_selector ".text-status-matched"
    assert_text "%"
    refute_selector ".text-status-review"
  end

  test "exceeding tolerance renders amber, not red" do
    tag = both_sided_load(50_000, 45_000) # -10%
    render_inline(DeltaCellComponent.new(tag: tag, metric: :net, show_pct: true))
    assert_selector ".text-status-review"
    refute_selector ".text-status-disputed"
  end

  test "renders nothing for a one-sided tag" do
    tag = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-ONE", net: 1000).tag
    render_inline(DeltaCellComponent.new(tag: tag, metric: :net))
    assert_no_selector "div"
  end
end
