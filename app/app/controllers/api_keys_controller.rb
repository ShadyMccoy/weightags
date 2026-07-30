class ApiKeysController < ApplicationController
  before_action :require_org
  before_action :require_admin

  def index
    @api_keys = current_org.api_keys.includes(:user).order(created_at: :desc)
    @new_token = flash[:new_token]
  end

  def create
    # Fail closed: a missing or unrecognised scope mints the weaker credential,
    # never the one that can post weighs.
    scope = params[:scope].to_s.presence_in(ApiKey.scopes.keys) || "read_only"
    key, raw = ApiKey.issue!(org: current_org, user: Current.user, name: params[:name], scope: scope)
    AuditEvent.record!(action: "api_key.created", subject: current_org, user: Current.user,
      actor_org: current_org, metadata: { name: key.name, key_id: key.public_id, scope: key.scope })
    redirect_to api_keys_path, flash: { new_token: raw, notice: "Created “#{key.name}”. Copy the token now — it won't be shown again." }
  end

  def destroy
    key = current_org.api_keys.find(params[:id])
    key.revoke!
    AuditEvent.record!(action: "api_key.revoked", subject: current_org, user: Current.user,
      actor_org: current_org, metadata: { name: key.name, key_id: key.public_id })
    redirect_to api_keys_path, notice: "Revoked “#{key.name}”."
  end
end
