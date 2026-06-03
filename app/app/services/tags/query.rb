require "csv"

module Tags
  class Query
    STATUS_OPTIONS = (
      Tag.states.keys.map { |s| [ s.humanize, s ] } + [ [ "Closed, not yet invoiced", "closed_unbilled" ] ]
    ).freeze

    def initialize(org:, params: {})
      @org = org
      @params = params
    end

    def results
      scope = base
      scope = by_text(scope)
      scope = by_status(scope)
      scope = by_partner(scope)
      scope = by_date(scope)
      scope = by_invoice(scope)
      scope.order(ship_date: :desc, updated_at: :desc)
    end

    def aggregates(scope = results)
      weighs = Weigh.where(org: @org, tag_id: scope.select(:id))
      {
        count: scope.count,
        gross: weighs.sum(:gross),
        tare:  weighs.sum(:tare),
        net:   weighs.sum(:net)
      }
    end

    def partners
      @org.partner_orgs.order(:name)
    end

    def to_csv(scope = results)
      scope = scope.includes(:sender_org, :receiver_org, :invoice_batch, :weighs)
      CSV.generate do |csv|
        csv << %w[bol ship_date commodity sender receiver truck driver
                  sender_net receiver_net delta_net status invoice_number]
        scope.each do |tag|
          csv << [
            tag.bol, tag.ship_date, tag.commodity,
            tag.sender_org.name, tag.receiver_org.name, tag.truck, tag.driver,
            tag.sender_weigh&.net, tag.receiver_weigh&.net, tag.net_delta,
            tag.state, tag.invoice_batch&.external_invoice_number
          ]
        end
      end
    end

    private

    def base
      Tag.for_org(@org)
    end

    def by_text(scope)
      q = @params[:q].to_s.strip
      return scope if q.blank?
      scope.where("tags.bol ILIKE :q OR tags.truck ILIKE :q OR tags.driver ILIKE :q", q: "%#{q}%")
    end

    def by_status(scope)
      status = @params[:status].to_s
      return scope if status.blank? || status == "all"
      return scope.closed_unbilled if status == "closed_unbilled"
      return scope unless Tag.states.key?(status)
      scope.where(state: status)
    end

    def by_partner(scope)
      partner_id = @params[:partner_id].presence
      return scope unless partner_id
      scope.where(sender_org_id: partner_id).or(scope.where(receiver_org_id: partner_id))
    end

    def by_date(scope)
      scope = scope.where("tags.ship_date >= ?", parse_date(@params[:from])) if @params[:from].present?
      scope = scope.where("tags.ship_date <= ?", parse_date(@params[:to]))   if @params[:to].present?
      scope
    end

    def by_invoice(scope)
      number = @params[:invoice_number].to_s.strip
      return scope if number.blank?
      scope.joins(:invoice_batch).where("invoice_batches.external_invoice_number ILIKE ?", "%#{number}%")
    end

    def parse_date(value)
      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
