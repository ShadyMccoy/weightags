class VerificationsController < ApplicationController
  allow_unauthenticated_access

  def show
    @batch = InvoiceBatch.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render plain: "Record not found", status: :not_found
  end
end
