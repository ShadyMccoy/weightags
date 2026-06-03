require "resolv"

class DomainsController < ApplicationController
  before_action :require_org
  before_action :require_admin, except: :confirm
  allow_unauthenticated_access only: :confirm

  def show
    @org = current_org
  end

  def update
    current_org.assign_domain!(params[:domain])
    confirm_email = params[:confirm_email].to_s.strip

    if confirm_email.present? && current_org.domain.present?
      DomainMailer.with(org: current_org, email: confirm_email,
        url: confirm_domain_url(current_org.domain_verification_token)).verify.deliver_later
      redirect_to domain_path, notice: "Verification email sent to #{confirm_email}."
    else
      redirect_to domain_path, notice: "Domain saved. Add the TXT record, or send a confirmation email."
    end
  end

  def confirm
    org = Org.find_by(domain_verification_token: params[:token].presence)
    if org.nil?
      return redirect_to(root_path, alert: "This verification link is invalid or has expired.")
    end
    verify!(org, via: "email")
    redirect_to authenticated? ? domain_path : new_session_path, notice: "#{org.domain} is verified."
  end

  def verify_dns
    org = current_org
    return redirect_to(domain_path, alert: "Set a domain first.") if org.domain.blank?

    if dns_txt_present?(org)
      verify!(org, via: "dns")
      redirect_to domain_path, notice: "#{org.domain} is verified via DNS."
    else
      redirect_to domain_path, alert: "Couldn't find that TXT record yet — DNS can take a while to propagate."
    end
  end

  private

  def verify!(org, via:)
    org.mark_domain_verified!
    AuditEvent.record!(action: "domain.verified", subject: org,
      user: (Current.user if authenticated?), actor_org: org,
      metadata: { domain: org.domain, via: via })
  end

  def dns_txt_present?(org)
    Resolv::DNS.open do |dns|
      dns.getresources(org.domain, Resolv::DNS::Resource::IN::TXT).any? do |record|
        record.strings.map(&:strip).include?(org.expected_txt_record)
      end
    end
  rescue Resolv::ResolvError, IOError, SocketError, Errno::ECONNREFUSED => e
    Rails.logger.warn("[Domain] DNS lookup failed for #{org.domain}: #{e.class}: #{e.message}")
    false
  end
end
