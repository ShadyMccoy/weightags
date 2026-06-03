class DomainMailer < ApplicationMailer
  def verify
    @org = params[:org]
    @url = params[:url]
    mail to: params[:email], subject: "Verify #{@org.domain} for WeighTags"
  end
end
