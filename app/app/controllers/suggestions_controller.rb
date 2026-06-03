class SuggestionsController < ApplicationController
  before_action :require_org
  before_action :set_suggestion

  def confirm
    stamp = current_org.id == @suggestion.sender_org_id ? :sender_confirmed_at : :receiver_confirmed_at
    @suggestion.update!(stamp => Time.current)
    AuditEvent.record!(action: "suggestion.confirmed_by", subject: @suggestion.sender_weigh.tag,
      user: Current.user, actor_org: current_org, bol: @suggestion.bol_sender,
      metadata: { side: stamp.to_s.sub("_confirmed_at", "") })

    if @suggestion.reload.both_confirmed?
      tag = Tags::Merge.confirm(@suggestion)
      redirect_to tag_path(tag), notice: "Matched — the weigh tags are now one tag."
    else
      redirect_back fallback_location: tags_path, notice: "Confirmed. Waiting on the partner to confirm too."
    end
  end

  def reject
    Tags::Merge.reject(@suggestion)
    redirect_back fallback_location: tags_path, notice: "Suggestion dismissed."
  end

  private

  def set_suggestion
    @suggestion = PairingSuggestion.where(sender_org_id: current_org.id)
      .or(PairingSuggestion.where(receiver_org_id: current_org.id))
      .pending.find(params[:id])
  end
end
