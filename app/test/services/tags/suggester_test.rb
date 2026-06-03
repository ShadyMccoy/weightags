require "test_helper"

class Tags::SuggesterTest < ActiveSupport::TestCase
  setup { @rel = build_relationship }

  def sender(bol, **attrs)
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user, bol: bol, **attrs)
  end

  def receiver(bol, **attrs)
    post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user, bol: bol, **attrs)
  end

  test "levenshtein measures edit distance" do
    assert_equal 1, Tags::Suggester.levenshtein("10849", "1O849".downcase) # o vs 0 after downcase => 1
    assert_equal 0, Tags::Suggester.levenshtein("ABC", "abc")
    assert_equal 1, Tags::Suggester.levenshtein("10849", "1084")  # one deletion
    assert_equal 2, Tags::Suggester.levenshtein("10849", "184")   # two deletions
  end

  test "a near-miss BOL with corroboration surfaces a pending suggestion, not a pair" do
    sender("BOL-1009", ship_date: Date.new(2026, 5, 1), truck: "T-9", gross: 50_000, tare: 10_000)
    receiver("BOL-1OO9", ship_date: Date.new(2026, 5, 1), truck: "T-9", gross: 50_050, tare: 10_000)

    s = PairingSuggestion.last
    assert s.present?
    assert s.pending?
    assert_equal "BOL-1009", s.bol_sender
    assert_equal 2, Tag.where(state: Tag.states[:pending]).count, "still two one-sided tags"
  end

  test "an uncorroborated near-miss does not suggest" do
    sender("BOL-2000", ship_date: Date.new(2026, 5, 1), truck: "T-1", gross: 50_000, tare: 10_000)
    receiver("BOL-2009", ship_date: Date.new(2026, 6, 30), truck: "Z-9", gross: 9_000, tare: 1_000)
    assert_equal 0, PairingSuggestion.count
  end

  test "mutual confirmation merges the weighs into one tag; the suggestion is audited" do
    s_res = sender("BOL-3001", ship_date: Date.new(2026, 5, 2), truck: "T-3", gross: 50_000, tare: 10_000)
    receiver("BOL-3O01", ship_date: Date.new(2026, 5, 2), truck: "T-3", gross: 50_040, tare: 10_000)
    suggestion = PairingSuggestion.last

    suggestion.update!(sender_confirmed_at: Time.current)
    refute suggestion.both_confirmed?

    suggestion.update!(receiver_confirmed_at: Time.current)
    tag = Tags::Merge.confirm(suggestion)

    assert suggestion.reload.confirmed?
    assert tag.both_sided?
    assert_equal s_res.tag.id, tag.id, "sender's tag is canonical"
    assert_equal "BOL-3001", tag.bol
    assert_equal tag.id, Weigh.find_by(bol: "BOL-3O01").tag_id, "receiver tag re-homed"
    assert AuditEvent.exists?(action: "suggestion.confirmed")
  end

  test "rejecting a suggestion leaves both weighs one-sided" do
    sender("BOL-4001", ship_date: Date.new(2026, 5, 3), truck: "T-4", gross: 50_000, tare: 10_000)
    receiver("BOL-4O01", ship_date: Date.new(2026, 5, 3), truck: "T-4", gross: 50_010, tare: 10_000)
    suggestion = PairingSuggestion.last

    Tags::Merge.reject(suggestion)
    assert suggestion.reload.rejected?
    assert_equal 2, Tag.where(state: Tag.states[:pending]).count
  end
end
