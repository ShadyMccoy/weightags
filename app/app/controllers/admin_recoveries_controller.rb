class AdminRecoveriesController < ApplicationController
  before_action :require_org

  def index
    @orgs = recoverable_orgs
  end

  def create
    org = recoverable_orgs.find { |o| o.id.to_s == params[:org_id].to_s }
    return redirect_to(admin_recoveries_path, alert: "That org isn't eligible for recovery.") if org.nil?

    membership = org.memberships.find_or_initialize_by(user: Current.user)
    membership.assign_attributes(role: :admin, ended_at: nil)
    membership.save!
    AuditEvent.record!(action: "admin.recovered", subject: org, user: Current.user, actor_org: org,
      metadata: { via: "domain", domain: org.domain })
    session[:active_org_id] = org.id
    redirect_to members_path, notice: "You're now an admin of #{org.name}."
  end

  private

  def recoverable_orgs
    domain = Current.user.email_address.to_s.split("@").last
    return [] if domain.blank?
    Org.claimed.where(domain: domain).where.not(domain_verified_at: nil).select do |org|
      !Current.user.admin_of?(org)
    end
  end
end
