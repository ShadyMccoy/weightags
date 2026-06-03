module Partnerships
  class Resync < ApplicationService
    def initialize(partnership)
      @partnership = partnership
    end

    def call
      affected.find_each do |tag|
        tag.tolerance_bps = @partnership.tolerance_bps
        tag.dispute_window_days = @partnership.dispute_window_days

        tag.reproject
        tag.clock_due_at = nil if tag.matched?
        tag.save!
        retarget_clock(tag)
        Tags::Broadcaster.refresh(tag)
      end
    end

    private

    def affected
      Tag.where(sender_org_id: @partnership.org_id,
                 receiver_org_id: @partnership.counterparty_org_id,
                 state: [ Tag.states[:matched], Tag.states[:review] ])
    end

    def retarget_clock(tag)
      if tag.review?
        if tag.clock_started_at
          tag.update_column(:clock_due_at, tag.clock_started_at + tag.dispute_window_days.days)
        else
          Tags::Clock.start!(tag)
        end
      end
    end
  end
end
