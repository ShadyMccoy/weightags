class ActivityController < ApplicationController
  before_action :require_org

  def index
    @events = feed_scope.recent_first.includes(:user, :actor_org).limit(300)
    @events = @events.where(action: params[:action_type]) if params[:action_type].present?
    if params[:q].present?
      @events = @events.where("bol ILIKE ?", "%#{params[:q].strip}%")
    end
    @action_types = AuditEvent.where(id: feed_scope.select(:id)).distinct.pluck(:action).sort
  end

  private

  def feed_scope
    load_ids = current_org.tags.select(:id)
    tag_ids = Weigh.where(tag_id: load_ids).select(:id)
    AuditEvent
      .where(subject_type: "Tag", subject_id: load_ids)
      .or(AuditEvent.where(subject_type: "Weigh", subject_id: tag_ids))
      .or(AuditEvent.where(actor_org_id: current_org.id))
  end
end
