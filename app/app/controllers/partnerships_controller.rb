class PartnershipsController < ApplicationController
  before_action :require_org

  def index
    @partnerships = current_org.partnerships.includes(:counterparty_org)
      .joins(:counterparty_org).order("orgs.name")
  end

  def update
    partnership = current_org.partnerships.find(params[:id])
    partnership.assign_attributes(
      tolerance_bps: tolerance_bps_from(params[:tolerance_percent]),
      dispute_window_days: params[:dispute_window_days]
    )

    if partnership.save
      Partnerships::Resync.call(partnership)
      AuditEvent.record!(action: "partnership.updated", subject: partnership.counterparty_org,
        user: Current.user, actor_org: current_org,
        metadata: { tolerance_bps: partnership.tolerance_bps, dispute_window_days: partnership.dispute_window_days })
      redirect_to partnerships_path, notice: "Updated settings for #{partnership.counterparty_org.name}."
    else
      redirect_to partnerships_path, alert: partnership.errors.full_messages.to_sentence
    end
  end

  private

  def tolerance_bps_from(percent)
    (percent.to_f * 100).round
  end
end
