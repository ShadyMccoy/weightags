require "test_helper"

class Tags::ActionsTest < ActiveSupport::TestCase
  setup do
    @rel = build_relationship
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-9", gross: 60_000, tare: 15_000) # sender net 45000
    res = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver,
      actor: @rel.buyer_user, bol: "BOL-9", gross: 59_000, tare: 15_000)  # receiver net 44000
    @tag = res.tag.reload
    assert @tag.review?
  end

  def buyer_actions  = Tags::Actions.new(tag: @tag, actor: @rel.buyer_user, actor_org: @rel.buyer)
  def grower_actions = Tags::Actions.new(tag: @tag, actor: @rel.grower_user, actor_org: @rel.grower)

  test "accept and compromise notify the partner, not just dispute" do
    assert_difference -> { Notification.where(kind: "tag.accepted", user: @rel.buyer_user).count }, 1 do
      grower_actions.accept!
    end
  end

  test "proposing a compromise notifies the partner" do
    assert_difference -> { Notification.where(kind: "tag.compromise_proposed", user: @rel.buyer_user).count }, 1 do
      grower_actions.propose_compromise!(canonical: { gross: 59_500, tare: 15_000, net: 44_500 })
    end
  end

  test "accept adopts the partner's values and resolves" do
    assert_difference -> { AuditEvent.where(action: "tag.accepted").count }, 1 do
      grower_actions.accept! # grower concedes to receiver's 44000
    end
    @tag.reload
    assert @tag.resolved?
    assert @tag.resolution_accepted_receiver?
    assert_equal 44_000, @tag.canonical_net
    assert_equal @rel.grower_user, @tag.resolved_by
  end

  test "dispute files a structured reason and pauses the clock" do
    assert_difference -> { AuditEvent.where(action: "tag.disputed").count }, 1 do
      buyer_actions.dispute!(reason: "Weight variance", notes: "Scale recalibrated")
    end
    @tag.reload
    assert @tag.disputed?
    assert_equal "Weight variance", @tag.dispute_reason
    assert_nil @tag.clock_due_at
  end

  test "editing own tag preserves prior values in the audit log and re-evaluates" do
    event_count = AuditEvent.where(action: "weigh.edited").count
    grower_actions.edit_weigh!(attributes: { gross: 59_000, tare: 15_000 }, reason: "Re-keyed") # now net 44000 == receiver
    edit = AuditEvent.where(action: "weigh.edited").last

    assert_equal event_count + 1, AuditEvent.where(action: "weigh.edited").count
    assert_equal "45000.0", edit.metadata.dig("before", "net")
    assert_equal "44000.0", edit.metadata.dig("after", "net")
    assert @tag.reload.matched?, "within tolerance after edit"
  end

  test "compromise can set canonical values matching neither weigh, then close" do
    grower_actions.propose_compromise!(canonical: { gross: 59_500, tare: 15_000, net: 44_500 }, note: "split it")
    @tag.reload
    assert @tag.compromise_proposed?
    assert_equal 44_500, @tag.canonical_net

    assert_difference -> { AuditEvent.where(action: "tag.compromise_accepted").count }, 1 do
      buyer_actions.accept_compromise!
    end
    assert @tag.reload.resolved?
    assert @tag.resolution_compromise?
  end

  test "a non-participant org cannot act on the tag" do
    outsider = Org.create!(name: "Outsider Co")
    user = User.create!(name: "Nope", email_address: "no@ex.test", password: "secret123")
    assert_raises(Tags::NotPermitted) do
      Tags::Actions.new(tag: @tag, actor: user, actor_org: outsider)
    end
  end

  test "a resolved tag cannot be accepted, disputed, or edited again" do
    grower_actions.accept!
    assert @tag.reload.resolved?

    [ -> { grower_actions.accept! }, -> { grower_actions.dispute!(reason: "x") },
      -> { grower_actions.edit_weigh!(attributes: { net: 1 }, reason: "x") } ].each do |attempt|
      assert_raises(Tags::NotPermitted) { attempt.call }
    end
    assert @tag.reload.resolution_accepted_receiver?, "resolution is unchanged"
  end

  test "a clean matched tag cannot be accepted (already agreed) but can be disputed" do
    post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender, actor: @rel.grower_user,
      bol: "BOL-M", gross: 50_000, tare: 10_000)
    m = post_tag(org: @rel.buyer, counterparty: @rel.grower, side: :receiver, actor: @rel.buyer_user,
      bol: "BOL-M", gross: 50_010, tare: 10_000).tag.reload
    assert m.matched?

    assert_raises(Tags::NotPermitted) do
      Tags::Actions.new(tag: m, actor: @rel.grower_user, actor_org: @rel.grower).accept!
    end
    assert_nothing_raised do
      Tags::Actions.new(tag: m, actor: @rel.grower_user, actor_org: @rel.grower).dispute!(reason: "Recount")
    end
    assert m.reload.disputed?
  end

  test "an invoiced tag is final — no transitions" do
    grower_actions.accept!
    InvoiceBatches::Create.new(org: @rel.grower, actor: @rel.grower_user,
      load_ids: [ @tag.id ], external_invoice_number: "INV-1").call
    assert @tag.reload.invoiced?
    assert_not @tag.can_dispute?
    assert_raises(Tags::NotPermitted) { grower_actions.dispute!(reason: "late") }
  end
end
