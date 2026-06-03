class WeighsController < ApplicationController
  include PartnerResolution
  before_action :require_org

  def new
    @into = open_partner_tags.find_by(id: params[:tag_id]) if params[:tag_id].present?
    @awaiting = open_partner_tags.includes(:sender_org, :receiver_org, :weighs).order(updated_at: :desc).limit(25)
    @weigh = Weigh.new(prefill(@into))
    @partners = partner_options
    @last = recent_entries
  end

  def create
    into = open_partner_tags.find_by(id: params[:tag_id]) if params[:tag_id].present?
    result = post_weigh(into)

    if result.nil?
      redirect_to new_weigh_path, alert: "Choose a partner for this weigh."
    elsif result.ok?
      redirect_to redirect_after(result, into), notice: "Saved weigh for BOL #{result.weigh.bol}."
    else
      @into = into
      @awaiting = open_partner_tags.limit(25)
      @weigh = result.weigh
      @partners = partner_options
      @last = recent_entries
      render :new, status: :unprocessable_entity
    end
  end

  private

  def open_partner_tags
    mine = Current.org.weighs.where.not(tag_id: nil).select(:tag_id)
    Tag.for_org(Current.org).pending.where.not(id: mine)
  end

  def post_weigh(into)
    if into
      Weighs::Poster.call(org: Current.org, actor: Current.user, attributes: weigh_params, into: into)
    else
      counterparty = resolve_counterparty
      return nil if counterparty.nil?
      Weighs::Poster.call(org: Current.org, counterparty: counterparty,
        side: chosen_side, actor: Current.user, attributes: weigh_params)
    end
  end

  def redirect_after(result, into)
    return tag_path(result.tag) if into
    new_weigh_path(counterparty_org_id: result.weigh.counterparty_org_id, side: result.weigh.side,
      commodity: result.weigh.commodity, truck: result.weigh.truck, driver: result.weigh.driver,
      scale_id: result.weigh.scale_id, weighed_by: result.weigh.weighed_by, ship_date: result.weigh.ship_date)
  end

  def weigh_params
    params.permit(:bol, :ship_date, :truck, :driver, :commodity, :gross, :tare,
      :net, :moisture, :grade, :weighed_by, :scale_id, :weighed_at, :notes)
  end

  def recent_entries
    Current.org.weighs.order(created_at: :desc).limit(5)
  end

  def prefill(into)
    last = recent_entries.first
    {
      bol: into&.bol,
      commodity: params[:commodity].presence || into&.commodity || last&.commodity,
      truck: params[:truck].presence || into&.truck,
      driver: params[:driver].presence || into&.driver,
      scale_id: params[:scale_id].presence || last&.scale_id,
      weighed_by: params[:weighed_by].presence || last&.weighed_by,
      ship_date: params[:ship_date].presence || into&.ship_date || Date.current
    }
  end
end
