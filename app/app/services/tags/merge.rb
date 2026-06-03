module Tags
  class Merge
    def self.confirm(suggestion) = new.confirm(suggestion)
    def self.merge!(**kw) = new.merge!(**kw)

    def confirm(suggestion)
      target = suggestion.sender_weigh.tag
      tag = nil
      ActiveRecord::Base.transaction do
        re_home([ suggestion.receiver_weigh ], into: target)
        finalize_pair(target, audit: "suggestion.confirmed",
          metadata: { merged_bol: suggestion.receiver_weigh.bol, distance: suggestion.distance })
        suggestion.update!(state: :confirmed)
        withdraw_competing(suggestion)
        tag = target
      end
      after_merge(tag)
    end

    def merge!(source:, target:, actor:, actor_org:)
      guard_merge!(source, target, actor_org)
      tag = nil
      ActiveRecord::Base.transaction do
        re_home(source.weighs.to_a, into: target)
        finalize_pair(target, audit: "tag.merged", actor: actor, actor_org: actor_org,
          metadata: { merged_bol: source.bol, manual: true })
        tag = target
      end
      after_merge(tag)
    end

    def self.reject(suggestion)
      suggestion.update!(state: :rejected)
      AuditEvent.record!(action: "suggestion.rejected", subject: suggestion.sender_weigh.tag,
        bol: suggestion.bol_sender, metadata: { rejected_bol: suggestion.bol_receiver })
    end

    private

    def guard_merge!(source, target, actor_org)
      raise NotPermitted, "not a party to these shipments" unless source.side_of(actor_org) && target.side_of(actor_org)
      raise NotPermitted, "already the same shipment" if source.id == target.id
      raise NotPermitted, "different relationship" unless
        source.sender_org_id == target.sender_org_id && source.receiver_org_id == target.receiver_org_id
      raise NotPermitted, "reopen the settled shipment first" if source.final? || target.final?
      sides = (source.weighs + target.weighs).map(&:side)
      raise NotPermitted, "both shipments have a weigh on the same side" if sides.size != sides.uniq.size
    end

    def re_home(weighs, into:)
      vacated = weighs.map(&:tag).uniq - [ into ]
      weighs.each { |w| w.update!(tag: into) }
      into.reset_weighs!
      vacated.each(&:discard_if_empty!)
    end

    def finalize_pair(target, audit:, metadata:, actor: nil, actor_org: nil)
      target.reproject
      target.save!
      AuditEvent.record!(action: audit, subject: target, user: actor, actor_org: actor_org,
        bol: target.bol, metadata: metadata)
      AuditEvent.record!(action: "tag.paired", subject: target, bol: target.bol,
        metadata: { within_tolerance: target.within_tolerance?, resulting_state: target.state })
    end

    def after_merge(tag)
      Clock.start!(tag) if tag.review?
      Broadcaster.refresh(tag)
      tag
    end

    def withdraw_competing(suggestion)
      PairingSuggestion.pending
        .for_tags([ suggestion.sender_weigh.id, suggestion.receiver_weigh.id ])
        .where.not(id: suggestion.id)
        .update_all(state: PairingSuggestion.states[:rejected])
    end
  end
end
