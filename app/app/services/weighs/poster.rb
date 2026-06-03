module Weighs
  class Poster < ApplicationService
    Result = Struct.new(:weigh, :tag, :ok, keyword_init: true) do
      def ok? = ok
    end

    def initialize(org:, actor:, attributes:, counterparty: nil, side: nil, into: nil)
      @org = org
      @actor = actor
      @attributes = attributes
      @into = into
      @counterparty = into ? into.counterparty_of(org) : counterparty
      @side = into ? into.side_of(org) : side
    end

    def call
      weigh = @org.weighs.new(@attributes)
      weigh.counterparty_org = @counterparty
      weigh.side = @side
      weigh.recorded_by = @actor
      if @into
        weigh.tag = @into
        weigh.bol = @into.bol
      end

      tag = nil
      ActiveRecord::Base.transaction do
        weigh.save!
        AuditEvent.record!(action: "weigh.posted", subject: weigh, user: @actor,
          actor_org: @org, bol: weigh.bol,
          metadata: { side: @side.to_s, net: weigh.net&.to_s, weigh_in: @into.present? })
        tag = Tags::Pairer.call(weigh)
      end
      Tags::Suggester.scan(weigh) if @into.nil? && tag&.one_sided?
      Notifier.tag_posted(weigh)
      Tags::Broadcaster.refresh(tag) if tag
      Result.new(weigh: weigh, tag: tag, ok: true)
    rescue ActiveRecord::RecordInvalid
      Result.new(weigh: weigh, tag: nil, ok: false)
    end
  end
end
