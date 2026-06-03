require "test_helper"
require "view_component/test_helpers"
require "view_component/test_case"

class VarianceStatusComponentTest < ViewComponent::TestCase
  setup { @rel = build_relationship }

  def load_with(sender_gross, receiver_gross)
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-VS#{SecureRandom.hex(2)}", gross: sender_gross, tare: 0)
    post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: Weigh.last(2).first.bol, gross: receiver_gross, tare: 0).tag.reload
  end

  test "within tolerance states the headline conclusion in green" do
    render_inline(VarianceStatusComponent.new(tag: load_with(50_000, 50_010)))
    assert_selector ".text-status-matched", text: /Within tolerance/
  end

  test "exceeding tolerance states it in amber with the threshold" do
    render_inline(VarianceStatusComponent.new(tag: load_with(50_000, 45_000)))
    assert_selector ".text-status-review", text: /Exceeds tolerance/
  end

  test "renders nothing when one-sided" do
    tag = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-VS-ONE", net: 1000).tag
    render_inline(VarianceStatusComponent.new(tag: tag))
    assert_no_selector "div"
  end
end
