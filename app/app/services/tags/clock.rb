module Tags
  class Clock
    REMINDER_MARKS = %i[half final].freeze

    class << self
      def start!(tag)
        return unless tag.review?
        return if tag.clock_due_at.present?

        now = Time.current
        tag.update!(
          clock_started_at: now,
          clock_due_at: now + tag.dispute_window_days.days,
          clock_reminded_half_at: nil,
          clock_reminded_final_at: nil
        )
      end

      def pause!(tag)
        tag.update!(clock_due_at: nil)
      end

      def process_due(now: Time.current)
        { reminded: fire_reminders(now), auto_accepted: fire_auto_accepts(now) }
      end

      def fire_reminders(now)
        count = 0
        running.find_each do |tag|
          count += 1 if maybe_remind(tag, :half, half_mark(tag), now)
          count += 1 if maybe_remind(tag, :final, final_mark(tag), now)
        end
        count
      end

      def fire_auto_accepts(now)
        count = 0
        running.where(clock_due_at: ..now).find_each do |tag|
          count += 1 if auto_accept!(tag, now: now)
        end
        count
      end

      def auto_accept!(tag, now: Time.current)
        return false unless tag.review?
        return false if tag.clock_due_at.nil? || tag.clock_due_at > now

        sender = tag.sender_weigh
        if sender.nil?
          Alerter.raise!(kind: "auto_accept_misfire",
            message: "auto-accept reached a review tag with no sender tag", tag_id: tag.id)
          return false
        end

        ActiveRecord::Base.transaction do
          tag.adopt_canonical_from(sender)
          tag.update!(state: :resolved, resolution: :auto_accepted, resolved_at: now, clock_due_at: nil)
          AuditEvent.record!(action: "tag.auto_accepted", subject: tag, bol: tag.bol,
            metadata: { defaulted_to: "sender", net: sender.net&.to_s, fired_at: now.iso8601 })
        end

        Rails.logger.info("[Tags::Clock] auto_accepted tag=#{tag.id} bol=#{tag.bol} net=#{sender.net}")
        notify(tag, :auto_accepted)
        Broadcaster.refresh(tag)
        true
      end

      private

      def running
        Tag.review.where.not(clock_due_at: nil)
      end

      def half_mark(tag)  = tag.clock_due_at - (tag.dispute_window_days.days / 2)
      def final_mark(tag) = tag.clock_due_at - 1.day

      def maybe_remind(tag, mark, at, now)
        column = "clock_reminded_#{mark}_at"
        return false if tag.public_send(column).present?
        return false unless now >= at && now < tag.clock_due_at

        AuditEvent.record!(action: "tag.reminder_sent", subject: tag, bol: tag.bol,
          metadata: { mark: mark.to_s, due_at: tag.clock_due_at.iso8601 })
        tag.update_column(column, now)
        notify(tag, :reminder, mark: mark)
        true
      end

      def notify(tag, kind, mark: nil)
        case kind
        when :reminder
          DisputeClockMailer.with(tag: tag, mark: mark).reminder.deliver_later
          Notifier.reminder(tag, mark)
        when :auto_accepted
          DisputeClockMailer.with(tag: tag).auto_accepted.deliver_later
          Notifier.auto_accepted(tag)
        end
      rescue => e
        Alerter.raise!(kind: "notification_delivery_failure",
          message: "dispute-clock #{kind} notification failed", tag_id: tag.id, error: e.message)
      end
    end
  end
end
