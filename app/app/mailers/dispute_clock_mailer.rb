class DisputeClockMailer < ApplicationMailer
  def reminder
    @tag = params[:tag]
    @mark = params[:mark]
    @days_left = ((@tag.clock_due_at - Time.current) / 1.day).ceil
    mail to: recipients(@tag), subject: "Action needed: BOL #{@tag.bol} closes in #{@days_left} day#{'s' unless @days_left == 1}"
  end

  def auto_accepted
    @tag = params[:tag]
    mail to: recipients(@tag), subject: "Recorded as uncontested: BOL #{@tag.bol}"
  end

  private

  def recipients(tag)
    tag.participant_users.map(&:email_address)
  end
end
