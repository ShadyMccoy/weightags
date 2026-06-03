require "test_helper"

class InviteAndRecoveryTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup { @rel = build_relationship }

  test "inviting a new partner by email creates a ghost org and emails a claim link" do
    sign_in_as @rel.grower_user
    assert_difference -> { Org.ghost.count }, 1 do
      assert_enqueued_emails 1 do
        post weighs_path, params: { new_partner_name: "Cedar Co", new_partner_email: "ops@cedar.test",
          bol: "BOL-INV", side: "sender", gross: 50_000, tare: 10_000 }
      end
    end
    ghost = Org.ghost.find_by(name: "Cedar Co")
    assert_equal "ops@cedar.test", Partnership.find_by(org: @rel.grower, counterparty_org: ghost).invite_email
  end

  test "the invitee views the diff before any password, then claims and is nudged" do
    ghost = Org.create!(name: "Cedar Co", claimed: false)
    Partnership.ensure!(org: @rel.grower, counterparty: ghost, invite_email: "ops@cedar.test")
    post_tag(org: @rel.grower, counterparty: ghost, side: :sender, actor: @rel.grower_user,
      bol: "BOL-CLAIM", gross: 50_000, tare: 10_000)
    token = ghost.generate_token_for(:claim)

    get claim_path(token)
    assert_response :success
    assert_match "BOL-CLAIM", response.body

    assert_difference -> { User.count }, 1 do
      post claim_path(token), params: { name: "Cedar Ops", email_address: "ops@cedar.test", password: "secret123" }
    end
    assert_redirected_to members_path
    assert_match(/invite a colleague/i, flash[:notice]) # D2 nudge
    ghost.reload
    assert ghost.claimed?
    assert User.find_by(email_address: "ops@cedar.test").admin_of?(ghost)
  end

  test "a domain verifies by email-confirmation link and enables same-domain admin recovery" do
    sign_in_as @rel.grower_user
    org = @rel.grower

    patch domain_path, params: { domain: "sycamore.test", confirm_email: "it@sycamore.test" }
    assert_not org.reload.domain_verified?
    assert org.domain_verification_token.present?

    post verify_dns_domain_path
    assert_not org.reload.domain_verified?, "DNS verification is real, not theater"

    get confirm_domain_path(org.domain_verification_token)
    assert org.reload.domain_verified?
    assert AuditEvent.exists?(action: "domain.verified")

    colleague = User.create!(name: "IT", email_address: "it@sycamore.test", password: "secret123")
    Membership.create!(user: colleague, org: Org.create!(name: "Elsewhere"), role: :member)
    sign_out
    sign_in_as colleague
    assert_difference -> { org.memberships.active.where(role: Membership.roles[:admin]).count }, 1 do
      post admin_recoveries_path, params: { org_id: org.id }
    end
    assert colleague.admin_of?(org)
  end
end
