class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to sign_up_path, alert: "Try again later." }

  def new
    @user = User.new
    @org_name = nil
  end

  def create
    @org_name = params[:org_name].to_s.strip
    @user = User.new(user_params)

    if @org_name.blank?
      @user.errors.add(:base, "Organization name is required")
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @user.save!
      Org.establish!(name: @org_name, admin: @user)
    end

    start_new_session_for @user
    redirect_to tags_path, notice: "Welcome to WeighTags."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def user_params
    params.permit(:name, :email_address, :password, :password_confirmation)
  end
end
