require "test_helper"

class Tags::MergeSplitTest < ActiveSupport::TestCase
  setup { @rel = build_relationship }

  def two_one_sided(bol_a:, bol_b:)
    a = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: bol_a, gross: 50_000, tare: 10_000).tag
    b = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: bol_b, gross: 50_010, tare: 10_000).tag
    [ a, b ]
  end

  test "manual merge folds one tag into another, discards the empty husk, keeps its audit" do
    target, source = two_one_sided(bol_a: "10849", bol_b: "1O849")
    source_id = source.id
    assert AuditEvent.exists?(action: "weigh.posted", subject_type: "Weigh") # source has events around it

    assert_difference -> { Tag.count }, -1 do
      Tags::Merge.merge!(source: source, target: target, actor: @rel.buyer_user, actor_org: @rel.buyer)
    end

    target.reload
    assert target.both_sided?
    assert target.matched?
    assert_not Tag.exists?(source_id), "the emptied husk is discarded"
    assert AuditEvent.exists?(action: "tag.merged"), "merge is audited"
    assert AuditEvent.where(bol: "1O849").exists?
  end

  test "split separates my weigh onto its own one-sided tag (reversible)" do
    target, source = two_one_sided(bol_a: "BOL-SP", bol_b: "BOL-SP2")
    merged = Tags::Merge.merge!(source: source, target: target, actor: @rel.buyer_user, actor_org: @rel.buyer)
    assert merged.both_sided?

    assert_difference -> { Tag.count }, 1 do
      @new_tag = Tags::Split.call(weigh: merged.weighs.detect(&:receiver?), actor: @rel.buyer_user, actor_org: @rel.buyer)
    end
    assert @new_tag.one_sided?
    assert merged.reload.one_sided?, "source keeps its other weigh"
    assert AuditEvent.exists?(action: "tag.split")
  end

  test "merge refuses across a settled record and across relationships" do
    target, source = two_one_sided(bol_a: "S1", bol_b: "S2")
    other = Org.create!(name: "Third Co")
    Partnership.ensure!(org: @rel.grower, counterparty: other)
    foreign = post_tag(org: @rel.grower, counterparty: other, side: :sender,
      actor: @rel.grower_user, bol: "S1", net: 1).tag
    assert_raises(Tags::NotPermitted) do
      Tags::Merge.merge!(source: foreign, target: target, actor: @rel.grower_user, actor_org: @rel.grower)
    end
  end

  test "split refuses on a one-sided tag and is participant-scoped" do
    a, = two_one_sided(bol_a: "X1", bol_b: "X2")
    assert_raises(Tags::NotPermitted) do # a is one-sided -> nothing to separate
      Tags::Split.call(weigh: a.weighs.first, actor: @rel.grower_user, actor_org: @rel.grower)
    end
  end
end
