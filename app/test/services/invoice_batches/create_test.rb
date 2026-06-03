require "test_helper"

class InvoiceBatches::CreateTest < ActiveSupport::TestCase
  setup do
    @rel = build_relationship
    @tag = matched_load("BOL-INV")
  end

  def matched_load(bol)
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: bol, gross: 50_000, tare: 10_000)
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: bol, gross: 50_010, tare: 10_000)
    res.tag.reload.tap { |l| assert l.matched? }
  end

  def create(org:, **opts)
    InvoiceBatches::Create.new(org: org, actor: @rel.grower_user, **opts).call
  end

  test "marks the tag invoiced, links the batch, and audits each tag + the batch" do
    result = nil
    assert_difference -> { AuditEvent.where(action: "tag.invoiced").count }, 1 do
      assert_difference -> { AuditEvent.where(action: "invoice_batch.created").count }, 1 do
        result = create(org: @rel.grower, load_ids: [ @tag.id ], external_invoice_number: "INV-900")
      end
    end
    assert result.ok?
    @tag.reload
    assert @tag.invoiced?
    assert_equal "INV-900", @tag.invoice_batch.external_invoice_number
    assert_equal @rel.grower, @tag.invoice_batch.sender_org
  end

  test "a closed tag belongs to at most one batch" do
    create(org: @rel.grower, load_ids: [ @tag.id ], external_invoice_number: "INV-1")
    result = create(org: @rel.grower, load_ids: [ @tag.id ], external_invoice_number: "INV-2")
    assert_not result.ok?
    assert_equal "INV-1", @tag.reload.invoice_batch.external_invoice_number
  end

  test "only the sender side can mark its tags invoiced" do
    result = InvoiceBatches::Create.new(org: @rel.buyer, actor: @rel.buyer_user,
      load_ids: [ @tag.id ], external_invoice_number: "INV-3").call
    assert_not result.ok?
    assert_not @tag.reload.invoiced?
  end

  test "an open (non-closed) tag is not eligible" do
    open = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-OPEN", net: 1000).tag
    result = create(org: @rel.grower, load_ids: [ open.id ], external_invoice_number: "INV-4")
    assert_not result.ok?
  end

  test "a blank invoice number is rejected" do
    result = create(org: @rel.grower, load_ids: [ @tag.id ], external_invoice_number: "  ")
    assert_not result.ok?
    assert_match(/invoice number/i, result.error)
  end
end
