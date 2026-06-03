class ClaimsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_org

  def show
    @tags = @org.tags.includes(:sender_org, :receiver_org, weighs: []).order(updated_at: :desc)
    @invite_email = Partnership.find_by(counterparty_org: @org)&.invite_email
  end

  def create
    email = params[:email_address].to_s.strip.downcase
    user = User.new(name: params[:name], email_address: email,
      password: params[:password], password_confirmation: params[:password])

    ActiveRecord::Base.transaction do
      user.save!
      @org.claim!(by: user)
    end

    start_new_session_for user
    session[:active_org_id] = @org.id
    redirect_to members_path, notice: "Welcome — #{@org.name} is yours. Invite a colleague so the organization isn't tied to a single account."
  rescue ActiveRecord::RecordInvalid
    @tags = @org.tags
    @invite_email = email
    @user = user
    render :show, status: :unprocessable_entity
  end

  private

  def set_org
    @org = Org.find_by_token_for(:claim, params[:token])
    return redirect_to(new_session_path, alert: "This invite link is invalid or has expired.") if @org.nil?
    redirect_to new_session_path, notice: "This organization has already been claimed — please sign in." if @org.claimed?
  end
end
