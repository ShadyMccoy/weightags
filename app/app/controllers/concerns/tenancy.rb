module Tenancy
  extend ActiveSupport::Concern

  included do
    before_action :set_current_org
    helper_method :current_org
  end

  private

  def set_current_org
    return unless authenticated?

    id = session[:active_org_id]
    org = Current.user.orgs.find_by(id: id) if id
    org ||= Current.user.default_org
    Current.org = org
    session[:active_org_id] = org&.id
    apply_rls_scope
  end

  def apply_rls_scope
    ids = Current.user.accessible_org_ids.join(",")
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql([ "SELECT set_config('app.accessible_org_ids', ?, false)", ids ])
    )
  rescue => e
    Rails.logger.warn("[Tenancy] could not set RLS scope: #{e.message}")
  end

  def current_org
    Current.org
  end

  def require_org
    return if Current.org
    redirect_to new_org_path, notice: "Create your organization to get started."
  end

  def require_admin
    return if Current.user&.admin_of?(Current.org)
    redirect_to tags_path, alert: "Only an admin can manage the organization."
  end
end
