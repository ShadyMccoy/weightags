module Tags
  class Pairer < ApplicationService
    def initialize(weigh)
      @weigh = weigh
    end

    def call
      tag = find_or_create_tag
      attach(tag)
      recompute(tag)
      tag
    end

    private

    attr_reader :weigh

    def sender_and_receiver
      if weigh.sender?
        [ weigh.org_id, weigh.counterparty_org_id ]
      else
        [ weigh.counterparty_org_id, weigh.org_id ]
      end
    end

    def find_or_create_tag
      return weigh.tag if weigh.tag

      sender_id, receiver_id = sender_and_receiver
      Tag.find_or_create_by!(sender_org_id: sender_id, receiver_org_id: receiver_id, bol: weigh.bol) do |l|
        l.commodity = weigh.commodity
        l.ship_date = weigh.ship_date
        l.truck = weigh.truck
        l.driver = weigh.driver
        settings = Partnership.settings_for(org: Org.find(sender_id), counterparty: Org.find(receiver_id))
        l.tolerance_bps = settings.tolerance_bps
        l.dispute_window_days = settings.dispute_window_days
        l.state = :pending
      end
    end

    def attach(tag)
      weigh.update!(tag: tag)
      tag.commodity ||= weigh.commodity
      tag.ship_date ||= weigh.ship_date
      tag.truck ||= weigh.truck
      tag.driver ||= weigh.driver
    end

    def recompute(tag)
      tag.reset_weighs!
      became_paired = tag.both_sided? && tag.pending?

      tag.reproject
      tag.save!

      if tag.review?
        Clock.start!(tag)
        Notifier.clock_started(tag) if became_paired
      end

      record_pairing_audit(tag) if became_paired
      tag
    end

    def record_pairing_audit(tag)
      AuditEvent.record!(
        action: "tag.paired",
        subject: tag,
        bol: tag.bol,
        metadata: {
          within_tolerance: tag.within_tolerance?,
          net_delta: tag.net_delta&.to_s,
          resulting_state: tag.state
        }
      )
    end
  end
end
