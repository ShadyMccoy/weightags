class InvitationMailer < ApplicationMailer
  def invite
    @org = params[:org]
    @from_org = params[:from_org]
    @claim_url = claim_url(@org.generate_token_for(:claim))
    mail to: params[:email], subject: "#{@from_org.name} shared weigh tags with you on WeighTags"
  end
end
