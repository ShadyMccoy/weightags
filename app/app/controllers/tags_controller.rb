class TagsController < ApplicationController
  before_action :require_org
  before_action :set_tag, only: %i[show accept dispute compromise accept_compromise note edit_weigh split merge]

  rescue_from Tags::NotPermitted do |e|
    redirect_back fallback_location: (@tag ? tag_path(@tag) : tags_path), alert: e.message
  end

  def index
    @query = Tags::Query.new(org: current_org, params: params)
    scope = @query.results.includes(:sender_org, :receiver_org, :invoice_batch, :sender_weigh, :receiver_weigh)
    @stats = summary_stats

    respond_to do |format|
      format.html do
        @tags = scope
        @aggregates = @query.aggregates(scope)
        @partners = @query.partners
      end
      format.csv do
        send_data @query.to_csv(scope),
          filename: "weightags-#{Date.current.iso8601}.csv", type: "text/csv"
      end
    end
  end

  def show
    @activity = @tag.related_audit_events.recent_first.includes(:user, :actor_org)
    @suggestions = PairingSuggestion.pending.for_tags(@tag.weighs.ids)
      .includes(:sender_org, :receiver_org)
    @merge_candidates = merge_candidates_for(@tag)
  end

  def accept
    act { |a| a.accept! }
  end

  def dispute
    act { |a| a.dispute!(reason: params[:reason], notes: params[:notes]) }
  end

  def compromise
    act do |a|
      a.propose_compromise!(
        canonical: { gross: params[:gross], tare: params[:tare], net: params[:net] },
        note: params[:note]
      )
    end
  end

  def accept_compromise
    act { |a| a.accept_compromise! }
  end

  def note
    act { |a| a.add_note!(body: params[:body]) }
  end

  def edit_weigh
    act { |a| a.edit_weigh!(attributes: edit_weigh_params, reason: params[:reason]) }
  end

  def split
    result = Tags::Split.call(weigh: @tag.weigh_for(current_org), actor: Current.user, actor_org: current_org)
    redirect_to tag_path(result), notice: "Separated your weigh into its own shipment."
  end

  def merge
    target = current_org.tags.find_by(id: params[:target_id])
    return redirect_to(tag_path(@tag), alert: "Choose a shipment to merge into.") unless target
    Tags::Merge.merge!(source: @tag, target: target, actor: Current.user, actor_org: current_org)
    redirect_to tag_path(target), notice: "Merged into BOL #{target.bol}."
  end

  private

  def set_tag
    @tag = current_org.tags.find(params[:id])
  end

  def merge_candidates_for(tag)
    return [] unless tag.one_sided? && !tag.final?
    my_sides = tag.weighs.map(&:side)
    current_org.tags.pending
      .where(sender_org_id: tag.sender_org_id, receiver_org_id: tag.receiver_org_id)
      .where.not(id: tag.id)
      .reject { |c| (c.weighs.map(&:side) & my_sides).any? }
  end

  def act
    yield Tags::Actions.new(tag: @tag, actor: Current.user, actor_org: current_org)
    redirect_to tag_path(@tag)
  end

  def edit_weigh_params
    params.permit(:gross, :tare, :net, :moisture, :grade, :notes)
  end

  def summary_stats
    by_state = current_org.tags.group(:state).count
    {
      pending:  by_state["pending"].to_i,
      review:   by_state["review"].to_i,
      disputed: by_state["disputed"].to_i,
      matched:  by_state["matched"].to_i
    }
  end
end
