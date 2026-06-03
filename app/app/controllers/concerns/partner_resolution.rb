module PartnerResolution
  extend ActiveSupport::Concern

  private

  def resolve_counterparty
    if params[:counterparty_org_id].present?
      Current.org.partner_orgs.find(params[:counterparty_org_id])
    elsif params[:new_partner_name].present?
      create_partner(params[:new_partner_name].strip, params[:new_partner_email].to_s.strip.presence)
    end
  end

  def create_partner(name, invite_email = nil)
    org = Org.create!(name: name, claimed: false)
    Partnership.ensure!(org: Current.org, counterparty: org, invite_email: invite_email)
    if invite_email
      InvitationMailer.with(org: org, from_org: Current.org, email: invite_email).invite.deliver_later
    end
    org
  end

  def partner_options
    Current.org.partner_orgs.order(:name)
  end

  def chosen_side
    params[:side].presence || "sender"
  end
end
