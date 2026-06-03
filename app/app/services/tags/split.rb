module Tags
  class Split < ApplicationService
    def initialize(weigh:, actor:, actor_org:)
      @weigh = weigh
      @actor = actor
      @actor_org = actor_org
    end

    def call
      source = @weigh&.tag
      raise NotPermitted, "no weigh of yours to separate" if @weigh.nil? || source.nil?
      raise NotPermitted, "not a party to this shipment" unless source.side_of(@actor_org)
      raise NotPermitted, "you can only move your own weigh" unless @weigh.org_id == @actor_org.id
      raise NotPermitted, "reopen the settled shipment first" if source.final?
      raise NotPermitted, "already one-sided — nothing to separate" unless source.both_sided?

      new_tag = nil
      ActiveRecord::Base.transaction do
        new_tag = Tag.create!(sender_org: source.sender_org, receiver_org: source.receiver_org,
          bol: distinct_bol(source), tolerance_bps: source.tolerance_bps,
          dispute_window_days: source.dispute_window_days, state: :pending)
        @weigh.update!(tag: new_tag)
        new_tag.reproject
        new_tag.save!
        source.reload.reproject.save!
        AuditEvent.record!(action: "tag.split", subject: new_tag, user: @actor, actor_org: @actor_org,
          bol: new_tag.bol, metadata: { from_bol: source.bol })
      end
      Broadcaster.refresh(new_tag)
      Broadcaster.refresh(source)
      new_tag
    end

    private

    def distinct_bol(source)
      base = @weigh.recorded_ref.presence || "SPLIT-#{@weigh.id}"
      taken = Tag.where(sender_org_id: source.sender_org_id, receiver_org_id: source.receiver_org_id, bol: base).exists?
      taken ? "#{base} (#{@weigh.id})" : base
    end
  end
end
