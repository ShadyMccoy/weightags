require "test_helper"

class WeighInTest < ActionDispatch::IntegrationTest
  setup do
    @rel = build_relationship
    @shipment = post_tag(org: @rel.grower, counterparty: @rel.buyer, side: :sender,
      actor: @rel.grower_user, bol: "BOL-UI-WI", gross: 50_000, tare: 10_000).tag
  end

  test "the receiver sees the sender's shipment awaiting their weigh and weighs in" do
    sign_in_as @rel.buyer_user

    get new_weigh_path
    assert_response :success
    assert_match "Awaiting your weigh", response.body
    assert_match "BOL-UI-WI", response.body

    assert_no_difference -> { Tag.count } do
      post weighs_path, params: { tag_id: @shipment.id, gross: 50_010, tare: 10_000 }
    end
    @shipment.reload
    assert_equal 2, @shipment.weighs.count
    assert @shipment.matched?
    assert_equal "receiver", @shipment.receiver_weigh.side
  end

  test "weighing in is scoped — a non-participant can't attach to the tag" do
    outsider = User.create!(name: "Out", email_address: "o@ex.test", password: "secret123")
    Membership.create!(user: outsider, org: Org.create!(name: "Outsider"), role: :admin)
    sign_in_as outsider
    post weighs_path, params: { tag_id: @shipment.id, gross: 1, tare: 0 }
    assert_redirected_to new_weigh_path
    assert_equal 1, @shipment.reload.weighs.count
  end
end
