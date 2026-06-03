require "test_helper"
require "view_component/test_helpers"
require "view_component/test_case"

class StatusPillComponentTest < ViewComponent::TestCase
  test "disputed renders the red conflict register" do
    render_inline(StatusPillComponent.new(status: "disputed"))
    assert_selector "span.bg-status-disputed", text: "Disputed"
  end

  test "review is amber, never red" do
    render_inline(StatusPillComponent.new(status: "review"))
    assert_selector "span.bg-status-review", text: "Review"
    refute_selector ".bg-status-disputed"
  end

  test "matched is the resolved-clean green" do
    render_inline(StatusPillComponent.new(status: "matched"))
    assert_selector "span.bg-status-matched", text: "Matched"
  end

  test "for_tag labels a one-sided tag with the side it awaits" do
    rel = build_relationship
    tag = post_tag(org: rel.grower, counterparty: rel.buyer, side: :sender,
      actor: rel.grower_user, bol: "BOL-PILL", net: 1000).tag
    render_inline(StatusPillComponent.for_tag(tag))
    assert_selector "span.bg-status-pending", text: "Awaiting receiver"
  end
end
