class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  def home
    redirect_to tags_path if authenticated? && Current.org
  end
end
