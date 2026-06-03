class MembersController < ApplicationController
  before_action :require_org
  before_action :require_admin, except: :index

  def index
    @memberships = current_org.memberships.includes(:user).order(:ended_at, created_at: :asc)
    @membership = Membership.new
  end

  def create
    email = params[:email_address].to_s.strip.downcase
    role = params[:role] == "admin" ? :admin : :member
    return redirect_to(members_path, alert: "Enter an email address.") if email.blank?

    user = User.find_by(email_address: email)
    new_user = user.nil?
    if new_user
      user = User.new(email_address: email, name: email.split("@").first.titleize,
        password: SecureRandom.base58(24))
      unless user.save
        return redirect_to members_path, alert: user.errors.full_messages.to_sentence
      end
    end

    if current_org.active_memberships.exists?(user: user)
      return redirect_to members_path, alert: "#{email} is already a member."
    end

    Membership.create!(user: user, org: current_org, role: role)
    PasswordsMailer.reset(user).deliver_later if new_user
    AuditEvent.record!(action: "membership.created", subject: current_org, user: Current.user,
      actor_org: current_org, metadata: { invited: email, role: role.to_s, new_user: new_user })

    redirect_to members_path, notice: "#{email} added as #{role}#{' (setup link sent)' if new_user}."
  end

  def update
    membership = current_org.memberships.active.find(params[:id])
    new_role = params[:role] == "admin" ? :admin : :member

    if membership.admin? && new_role == :member && current_org.sole_admin?
      return redirect_to members_path, alert: "Promote another admin before demoting the last one."
    end

    membership.update!(role: new_role)
    AuditEvent.record!(action: "membership.role_changed", subject: current_org, user: Current.user,
      actor_org: current_org, metadata: { user: membership.user.email_address, role: new_role.to_s })
    redirect_to members_path, notice: "#{membership.user.display_name} is now #{new_role}."
  end

  def destroy
    membership = current_org.memberships.active.find(params[:id])

    if membership.admin? && current_org.sole_admin?
      return redirect_to members_path, alert: "Add another admin before removing the last one."
    end

    membership.end!
    AuditEvent.record!(action: "membership.ended", subject: current_org, user: Current.user,
      actor_org: current_org, metadata: { user: membership.user.email_address })
    redirect_to members_path, notice: "#{membership.user.display_name}'s access ended."
  end
end
