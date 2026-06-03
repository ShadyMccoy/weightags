require "test_helper"

class AuditEventTest < ActiveSupport::TestCase
  setup do
    @event = AuditEvent.record!(action: "test.seed", metadata: { a: 1 })
  end

  test "UPDATE on audit_events fails at the database" do
    assert_raises(ActiveRecord::StatementInvalid) do
      AuditEvent.connection.execute(
        "UPDATE audit_events SET action = 'tampered' WHERE id = #{@event.id}"
      )
    end
  end

  test "DELETE on audit_events fails at the database" do
    assert_raises(ActiveRecord::StatementInvalid) do
      AuditEvent.connection.execute("DELETE FROM audit_events WHERE id = #{@event.id}")
    end
  end

  test "the model also refuses update and destroy" do
    assert_raises(ActiveRecord::ReadOnlyRecord) { @event.update!(action: "x") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { @event.destroy }
  end

  test "actor label cites the user and org parenthetically, never the role" do
    rel = build_relationship
    event = AuditEvent.record!(action: "tag.disputed", user: rel.buyer_user, actor_org: rel.buyer)
    assert_equal "Jessica Miller (Pacific Hulling Co)", event.actor_label
    assert_equal "WeighTags", AuditEvent.record!(action: "tag.paired").actor_label
  end
end
