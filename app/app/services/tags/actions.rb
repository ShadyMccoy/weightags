module Tags
  class Actions
    def initialize(tag:, actor:, actor_org:)
      @tag = tag
      @actor = actor
      @actor_org = actor_org
      ensure_participant!
    end

    attr_reader :tag, :actor, :actor_org

    def accept!
      guard!(tag.can_accept?, "this tag can't be accepted in its current state")
      partner_weigh = tag.side_of(actor_org) == :sender ? tag.receiver_weigh : tag.sender_weigh

      transition("tag.accepted",
        metadata: { accepted_side: partner_weigh.side, net: partner_weigh.net&.to_s },
        notify: -> { Notifier.accepted(tag, actor_org) }) do
        tag.adopt_canonical_from(partner_weigh)
        tag.assign_attributes(state: :resolved,
          resolution: partner_weigh.sender? ? :accepted_sender : :accepted_receiver,
          resolved_by: actor, resolved_at: Time.current, clock_due_at: nil)
      end
    end

    def dispute!(reason:, notes: nil)
      guard!(tag.can_dispute?, "this tag can't be disputed in its current state")
      transition("tag.disputed",
        metadata: { reason: reason, notes: notes },
        notify: -> { Notifier.disputed(tag, actor_org) }) do
        tag.assign_attributes(state: :disputed, dispute_reason: reason,
          dispute_notes: notes, clock_due_at: nil)
      end
    end

    def edit_weigh!(attributes:, reason:)
      guard!(tag.can_edit_tag?(actor_org), "this tag can't be edited in its current state")
      weigh = tag.weigh_for(actor_org)

      attrs = attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : attributes.to_h
      attrs = attrs.symbolize_keys
      attrs[:net] = nil if (attrs.key?(:gross) || attrs.key?(:tare)) && attrs[:net].blank?

      before = weigh.slice(*Tag::COMPARED_METRICS.map(&:to_s))
      weigh.assign_attributes(attrs)
      weigh.save!
      after = weigh.slice(*Tag::COMPARED_METRICS.map(&:to_s))

      AuditEvent.record!(action: "weigh.edited", subject: weigh, user: actor,
        actor_org: actor_org, bol: tag.bol,
        metadata: { reason: reason, before: before, after: after })

      transition("tag.reopened",
        metadata_after: -> { { resulting_state: tag.state } },
        notify: -> { Notifier.tag_edited(tag, actor_org) }) do
        tag.assign_attributes(dispute_reason: nil, dispute_notes: nil)
        tag.reproject(force: true)
      end
      Clock.start!(tag) if tag.review?
      tag
    end

    def propose_compromise!(canonical:, note: nil)
      guard!(tag.can_propose_compromise?, "a compromise can't be proposed in this state")
      transition("tag.compromise_proposed",
        metadata: { canonical: canonical, note: note },
        notify: -> { Notifier.compromise_proposed(tag, actor_org) }) do
        tag.assign_attributes(state: :compromise_proposed,
          canonical_gross: canonical[:gross], canonical_tare: canonical[:tare], canonical_net: canonical[:net])
      end
    end

    def accept_compromise!
      guard!(tag.can_accept_compromise?, "no compromise is awaiting acceptance")
      transition("tag.compromise_accepted",
        metadata: { net: tag.canonical_net&.to_s },
        notify: -> { Notifier.compromise_accepted(tag, actor_org) }) do
        tag.assign_attributes(state: :resolved, resolution: :compromise,
          resolved_by: actor, resolved_at: Time.current, clock_due_at: nil)
      end
    end

    def add_note!(body:)
      transition("tag.note_added", metadata: { body: body }) { }
    end

    private

    def ensure_participant!
      return if tag.side_of(actor_org)
      raise NotPermitted, "your org is not a party to this tag"
    end

    def guard!(allowed, message)
      raise NotPermitted, message unless allowed
    end

    def transition(action, metadata: {}, metadata_after: nil, notify: nil)
      ActiveRecord::Base.transaction do
        yield
        tag.save!
        meta = metadata_after ? metadata.merge(metadata_after.call) : metadata
        AuditEvent.record!(action: action, subject: tag, user: actor,
          actor_org: actor_org, bol: tag.bol, metadata: meta)
      end
      Broadcaster.refresh(tag)
      notify&.call
      tag
    end
  end
end
