class NotificationMailer < ApplicationMailer
  def notify
    @notification = params[:notification]
    mail to: @notification.user.email_address, subject: @notification.title
  end
end
