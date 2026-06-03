require "test_helper"

class Tags::QueryTest < ActiveSupport::TestCase
  setup do
    @rel = build_relationship
    @other = Org.create!(name: "Other Buyer Co")
    Partnership.ensure!(org: @rel.grower, counterparty: @other)

    @a = sender_weigh("BOL-A", date: Date.new(2026, 5, 1), truck: "T-1", net_gross: 50_000, partner: @rel.buyer).tag
    @b = sender_weigh("BOL-B", date: Date.new(2026, 5, 20), truck: "T-2", net_gross: 60_000, partner: @rel.buyer).tag
    @c = sender_weigh("BOL-C", date: Date.new(2026, 6, 10), truck: "T-3", net_gross: 40_000, partner: @other).tag
  end

  def sender_weigh(bol, date:, truck:, net_gross:, partner:)
    post_tag(org: @rel.grower, counterparty: partner, side: :sender, actor: @rel.grower_user,
      bol: bol, ship_date: date, truck: truck, gross: net_gross, tare: 10_000)
  end

  def query(params) = Tags::Query.new(org: @rel.grower, params: params)

  test "text search matches BOL and truck" do
    assert_equal ["BOL-A"], query(q: "bol-a").results.pluck(:bol)
    assert_equal ["BOL-B"], query(q: "T-2").results.pluck(:bol)
  end

  test "partner filter scopes to one relationship" do
    assert_equal %w[BOL-C], query(partner_id: @other.id).results.pluck(:bol)
    assert_equal %w[BOL-B BOL-A], query(partner_id: @rel.buyer.id).results.pluck(:bol) # date desc
  end

  test "ship-date range is inclusive" do
    bols = query(from: "2026-05-15", to: "2026-05-31").results.pluck(:bol)
    assert_equal %w[BOL-B], bols
  end

  test "aggregates sum the viewer's own recorded weights over the filtered set" do
    agg = query({}).aggregates
    assert_equal 3, agg[:count]
    assert_equal 150_000, agg[:gross]   # 50k + 60k + 40k
    assert_equal 30_000, agg[:tare]     # 3 * 10k
    assert_equal 120_000, agg[:net]
  end

  test "Closed, not yet invoiced selects resolved/matched tags without a batch" do
    post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-A", gross: 50_010, tare: 10_000)
    assert @a.reload.matched?
    assert_includes query(status: "closed_unbilled").results.pluck(:bol), "BOL-A"
    assert_not_includes query(status: "closed_unbilled").results.pluck(:bol), "BOL-B" # still pending
  end

  test "CSV export contains a header and exactly the filtered rows" do
    csv = CSV.parse(query(partner_id: @rel.buyer.id).to_csv, headers: true)
    assert_equal %w[BOL-B BOL-A], csv["bol"]
    assert_includes csv.headers, "invoice_number"
  end
end
