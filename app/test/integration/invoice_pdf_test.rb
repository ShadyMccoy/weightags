require "test_helper"

class InvoicePdfTest < ActionDispatch::IntegrationTest
  setup do
    @rel = build_relationship
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-PDF", ship_date: Date.new(2026, 5, 9), gross: 50_000, tare: 10_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-PDF", gross: 50_010, tare: 10_000)
    @tag = res.tag.reload
    @batch = InvoiceBatches::Create.new(org: @rel.grower, actor: @rel.grower_user,
      load_ids: [ @tag.id ], external_invoice_number: "INV-PDF-1").call.batch
  end

  test "the batch renders a print-clean PDF artifact" do
    sign_in_as @rel.grower_user
    get pdf_invoice_batch_path(@batch)
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF-"), "is a PDF document"
  end

  test "both parties can view the batch; outsiders cannot" do
    sign_in_as @rel.buyer_user
    get invoice_batch_path(@batch)
    assert_response :success
    assert_match "INV-PDF-1", response.body

    outsider = User.create!(name: "Out", email_address: "out@ex.test", password: "secret123")
    Membership.create!(user: outsider, org: Org.create!(name: "Other"), role: :admin)
    sign_out
    sign_in_as outsider
    get invoice_batch_path(@batch)
    assert_response :not_found
  end

  test "the public verification page resolves by token without authentication" do
    get verify_path(@batch.token)
    assert_response :success
    assert_match "INV-PDF-1", response.body
    assert_match "record verification", response.body

    get verify_path("does-not-exist")
    assert_response :not_found
  end
end
