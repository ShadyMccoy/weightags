class OrgsController < ApplicationController
  def new
    @org = Org.new
  end

  def create
    name = params.dig(:org, :name) || params[:name]
    @org = Org.establish!(name: name, admin: Current.user)
    session[:active_org_id] = @org.id
    redirect_to tags_path, notice: "#{@org.name} is ready."
  rescue ActiveRecord::RecordInvalid
    @org = Org.new(name: name).tap(&:valid?)
    render :new, status: :unprocessable_entity
  end

  def switch
    org = Current.user.orgs.find(params[:id])
    session[:active_org_id] = org.id
    redirect_back fallback_location: tags_path, notice: "Switched to #{org.name}."
  end
end
