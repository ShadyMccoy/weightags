require "application_system_test_case"

class InvoiceFlowTest < ApplicationSystemTestCase
  setup do
    @rel = build_relationship
    @tags = %w[BOL-B1 BOL-B2].map do |bol|
      post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
        bol: bol, gross: 50_000, tare: 10_000)
      post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
        bol: bol, gross: 50_010, tare: 10_000).tag.reload
    end
  end

  test "the select-all checkbox (Stimulus) ticks every row, then marks them invoiced" do
    login_as @rel.grower_user
    visit new_invoice_batch_path

    fill_in "external_invoice_number", with: "INV-SYS-9"
    find("input[type=checkbox][data-checkall-target='all']").check  # JS ticks all rows

    @tags.each { |l| assert find("input[type=checkbox][value='#{l.id}']").checked? }

    click_button "Mark selected as invoiced"
    assert @tags.all? { |l| l.reload.invoiced? }
  end

  test "the receiver verifies an invoiced tag by its invoice number" do
    InvoiceBatches::Create.new(org: @rel.grower, actor: @rel.grower_user,
      load_ids: [ @tags.first.id ], external_invoice_number: "INV-FIND-1").call

    login_as @rel.buyer_user
    visit tags_path(invoice_number: "INV-FIND-1")
    assert_text "BOL-B1"
    assert_text "INV-FIND-1"
  end
end
