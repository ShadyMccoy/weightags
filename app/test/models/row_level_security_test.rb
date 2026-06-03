require "test_helper"

class RowLevelSecurityTest < ActiveSupport::TestCase
  setup do
    ActiveRecord::Base.connection.execute(
      "GRANT SELECT, INSERT, UPDATE, DELETE ON weighs, tags, invoice_batches TO weightags_app"
    )
    @rel = build_relationship
    res = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-RLS", net: 1000)
    @tag = res.tag
    @outsider = Org.create!(name: "Outsider Co")
  end

  def as_app_scoped(org_ids)
    conn = ActiveRecord::Base.connection
    conn.execute("SET ROLE weightags_app")
    conn.execute(ActiveRecord::Base.sanitize_sql([ "SELECT set_config('app.accessible_org_ids', ?, false)", org_ids.join(",") ]))
    yield conn
  ensure
    conn.execute("RESET ROLE")
    conn.execute("SELECT set_config('app.accessible_org_ids', '', false)")
  end

  test "an org sees its own tags under RLS" do
    as_app_scoped([ @rel.grower.id ]) do |conn|
      assert_equal 1, conn.select_value("SELECT count(*) FROM tags WHERE id = #{@tag.id}").to_i
      assert_operator conn.select_value("SELECT count(*) FROM weighs").to_i, :>=, 1
    end
  end

  test "RLS denies access to a tag from an unrelated org" do
    as_app_scoped([ @outsider.id ]) do |conn|
      assert_equal 0, conn.select_value("SELECT count(*) FROM tags WHERE id = #{@tag.id}").to_i
      assert_equal 0, conn.select_value("SELECT count(*) FROM weighs WHERE bol = 'BOL-RLS'").to_i
    end
  end

  test "with no scope set, RLS exposes nothing" do
    conn = ActiveRecord::Base.connection
    conn.execute("SET ROLE weightags_app")
    begin
      assert_equal 0, conn.select_value("SELECT count(*) FROM tags").to_i
    ensure
      conn.execute("RESET ROLE")
    end
  end
end
