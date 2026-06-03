require "application_system_test_case"

class DisputeFlowTest < ApplicationSystemTestCase
  setup do
    @rel = build_relationship
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-SYS", gross: 60_000, tare: 15_000)
    @tag = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-SYS", gross: 59_000, tare: 15_000).tag.reload
  end

  test "the dispute panel reveals on click, and filing it transitions the tag" do
    login_as @rel.buyer_user
    visit tag_path(@tag)

    assert_text "Exceeds tolerance"
    assert_no_field "notes"

    click_button "Dispute"

    select "Weight variance", from: "reason"
    fill_in "notes", with: "Re-weigh requested"
    click_button "Submit dispute"

    assert_text "Dispute filed"
    assert @tag.reload.disputed?
  end

  test "a clean matched tag offers the contest path but not Accept" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-CLEAN", gross: 50_000, tare: 10_000)
    matched = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-CLEAN", gross: 50_010, tare: 10_000).tag.reload
    assert matched.matched?

    login_as @rel.grower_user
    visit tag_path(matched)
    assert_button "Dispute"
    assert_no_button "Accept partner's numbers"
  end
end
