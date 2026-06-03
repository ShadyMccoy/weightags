require "application_system_test_case"

class OrgSwitchingTest < ApplicationSystemTestCase
  setup do
    @rel = build_relationship
    @second = Org.create!(name: "Second Harvest Co")
    Membership.create!(user: @rel.grower_user, org: @second, role: :admin)
  end

  test "switching orgs changes the active tenant" do
    login_as @rel.grower_user
    assert_text "Reconciliation dashboard for #{@rel.grower.name}"

    find("button", text: @rel.grower.name).click   # open the dropdown
    click_button "Second Harvest Co"                # pick the other org

    assert_text "Reconciliation dashboard for Second Harvest Co"
  end
end
