module Api
  # The single outward-facing object. A "weigh tag" is one shipment seen from the
  # caller's org: their own weigh, the partner's weigh, and the reconciliation
  # status — the Tag/Weigh split is an internal concern and never leaks here.
  #
  # Weights are decimal strings to preserve precision (this is a money-adjacent
  # system of record); deltas follow the product's sender→receiver convention.
  class WeighTagSerializer
    WEIGH_FIELDS = %i[gross tare net moisture grade weighed_by scale_id notes].freeze

    def self.call(tag, org)
      new(tag, org).as_json
    end

    def initialize(tag, org)
      @tag = tag
      @org = org
    end

    def as_json
      {
        id: @tag.id,
        bol: @tag.bol,
        status: status,
        role: @tag.side_of(@org)&.to_s,
        partner: { id: partner.id, name: partner.name },
        ship_date: @tag.ship_date&.iso8601,
        commodity: @tag.commodity,
        truck: @tag.truck,
        driver: @tag.driver,
        mine: weigh_json(@tag.weigh_for(@org)),
        partner_weigh: weigh_json(@tag.weigh_for(partner)),
        net_delta: @tag.net_delta&.to_s,
        net_delta_percent: @tag.net_delta_percent&.to_s,
        within_tolerance: @tag.both_sided? ? @tag.within_tolerance? : nil,
        canonical_net: @tag.canonical_net&.to_s,
        invoice_number: @tag.invoice_batch&.external_invoice_number,
        created_at: @tag.created_at.iso8601,
        updated_at: @tag.updated_at.iso8601
      }
    end

    private

    def partner
      @partner ||= @tag.counterparty_of(@org)
    end

    # Public status vocabulary. Pending splits by who the caller is still waiting
    # on, which is what a headless sync actually needs to know.
    def status
      if @tag.pending?
        @tag.weigh_for(@org) ? "awaiting_partner" : "awaiting_you"
      else
        @tag.state
      end
    end

    def weigh_json(weigh)
      return nil if weigh.nil?
      fields = WEIGH_FIELDS.index_with do |f|
        value = weigh.public_send(f)
        value.is_a?(BigDecimal) ? value.to_s : value
      end
      fields.merge(
        recorded_ref: weigh.recorded_ref,
        weighed_at: weigh.weighed_at&.iso8601
      )
    end
  end
end
