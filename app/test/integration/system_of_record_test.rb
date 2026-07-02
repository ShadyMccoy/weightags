require "test_helper"

class SystemOfRecordTest < ActionDispatch::IntegrationTest
  setup do
    @rel = build_relationship
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-SOR", ship_date: Date.new(2026, 5, 5), gross: 50_000, tare: 10_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-SOR", gross: 50_010, tare: 10_000)
    @tag = res.tag.reload
  end

  test "the filtered view exports exactly its rows to CSV" do
    sign_in_as @rel.grower_user
    get tags_path(format: :csv, q: "BOL-SOR")
    assert_response :success
    assert_equal "text/csv", response.media_type
    rows = CSV.parse(response.body, headers: true)
    assert_equal [ "BOL-SOR" ], rows["bol"]
  end

  test "sender marks invoiced and the receiver verifies by invoice number" do
    sign_in_as @rel.grower_user
    post invoice_batches_path, params: { external_invoice_number: "INV-555", load_ids: [ @tag.id ] }
    assert @tag.reload.invoiced?
    sign_out

    sign_in_as @rel.buyer_user
    get tags_path(invoice_number: "INV-555")
    assert_response :success
    assert_match "BOL-SOR", response.body
    assert_match "INV-555", response.body
  end
end
