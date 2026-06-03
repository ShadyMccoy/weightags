require "test_helper"

class AccessModelTest < ActiveSupport::TestCase
  setup { @rel = build_relationship }

  test "the tenant wall is the user's active-membership orgs" do
    assert_equal [ @rel.grower.id ], @rel.grower_user.accessible_org_ids

    second = Org.create!(name: "Second Co")
    Membership.create!(user: @rel.grower_user, org: second, role: :member)
    assert_equal [ @rel.grower.id, second.id ].sort, @rel.grower_user.accessible_org_ids.sort
  end

  test "ending a membership drops the org from the wall" do
    membership = Membership.create!(user: @rel.grower_user, org: Org.create!(name: "Temp"), role: :member)
    assert_includes @rel.grower_user.accessible_org_ids, membership.org_id
    membership.end!
    assert_not_includes @rel.grower_user.reload.accessible_org_ids, membership.org_id
  end

  test "a shared Tag resolves to both participant orgs through the one predicate" do
    tag = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-ACC", net: 1000).tag
    assert_includes Tag.for_org(@rel.grower), tag
    assert_includes Tag.for_org(@rel.buyer), tag

    outsider = Org.create!(name: "Outsider")
    assert_not_includes Tag.for_org(outsider), tag
  end
end
