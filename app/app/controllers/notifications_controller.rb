class NotificationsController < ApplicationController
  before_action :require_org

  def index
    @notifications = scope.recent_first.limit(100)
  end

  def update
    notification = scope.find(params[:id])
    notification.mark_read!
    target = notification.subject.is_a?(Tag) ? tag_path(notification.subject) : notifications_path
    redirect_to target
  end

  def read_all
    scope.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All caught up."
  end

  private

  def scope
    Current.user.notifications.where(org: current_org)
  end
end
