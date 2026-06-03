class Notifier
  class << self
    def tag_posted(weigh)
      tag = weigh.tag
      publish(kind: "weigh.posted", recipients: members(weigh.counterparty_org), subject: tag,
        url: tag_url(tag),
        title: "New weigh tag from #{weigh.org.name}",
        body: "BOL #{weigh.bol}#{" (net #{fmt weigh.net} lb)" if weigh.net}")
    end

    def clock_started(tag)
      publish(kind: "clock.started", recipients: both(tag), subject: tag, url: tag_url(tag),
        title: "Review window open: BOL #{tag.bol}",
        body: "Deltas exceed tolerance. The dispute window closes #{tag.clock_due_at&.strftime('%b %-d, %Y')}.")
    end

    def disputed(tag, actor_org)
      publish(kind: "tag.disputed", recipients: members(tag.counterparty_of(actor_org)), subject: tag,
        url: tag_url(tag),
        title: "Dispute filed: BOL #{tag.bol}",
        body: [ tag.dispute_reason, tag.dispute_notes ].compact.join(" — "))
    end

    def tag_edited(tag, actor_org)
      publish(kind: "weigh.edited", recipients: members(tag.counterparty_of(actor_org)), subject: tag,
        url: tag_url(tag),
        title: "Partner edited their tag: BOL #{tag.bol}",
        body: "Please re-review the comparison.")
    end

    def accepted(tag, actor_org)
      publish(kind: "tag.accepted", recipients: members(tag.counterparty_of(actor_org)), subject: tag,
        url: tag_url(tag),
        title: "Numbers accepted: BOL #{tag.bol}",
        body: "#{actor_org.name} accepted the agreed values (net #{fmt tag.canonical_net} lb).")
    end

    def compromise_proposed(tag, actor_org)
      publish(kind: "tag.compromise_proposed", recipients: members(tag.counterparty_of(actor_org)), subject: tag,
        url: tag_url(tag),
        title: "Compromise proposed: BOL #{tag.bol}",
        body: "#{actor_org.name} proposed net #{fmt tag.canonical_net} lb. Review and accept or dispute.")
    end

    def compromise_accepted(tag, actor_org)
      publish(kind: "tag.compromise_accepted", recipients: members(tag.counterparty_of(actor_org)), subject: tag,
        url: tag_url(tag),
        title: "Compromise accepted: BOL #{tag.bol}",
        body: "Recorded at net #{fmt tag.canonical_net} lb.")
    end

    def invoiced(tag)
      publish(kind: "tag.invoiced", recipients: members(tag.receiver_org), subject: tag,
        url: tag_url(tag),
        title: "Weigh tag invoiced: BOL #{tag.bol}",
        body: "Linked to invoice #{tag.invoice_batch&.external_invoice_number}.")
    end

    def auto_accepted(tag)
      publish(kind: "tag.auto_accepted", recipients: both(tag), subject: tag, url: tag_url(tag),
        email: false,
        title: "Recorded as uncontested: BOL #{tag.bol}",
        body: "The window closed; defaulted to the sender's values (net #{fmt tag.canonical_net} lb).")
    end

    def reminder(tag, mark)
      publish(kind: "clock.reminder", recipients: both(tag), subject: tag, url: tag_url(tag),
        email: false,
        title: "#{mark == :final ? 'Final reminder' : 'Reminder'}: BOL #{tag.bol} window closing",
        body: "Closes #{tag.clock_due_at&.strftime('%b %-d, %Y')}. File a dispute to pause it.")
    end

    private

    def publish(kind:, recipients:, title:, body:, subject: nil, url: nil, email: true)
      Array(recipients).uniq.each do |user|
        org = org_context(user, subject)
        next unless org
        notification = Notification.create!(user: user, org: org, kind: kind, title: title,
          body: body, subject: subject, url: url)
        deliver(notification) if email
      end
    end

    def deliver(notification)
      NotificationMailer.with(notification: notification).notify.deliver_later
    rescue => e
      Alerter.raise!(kind: "notification_delivery_failure",
        message: "Failed to enqueue notification email", notification_id: notification.id, error: e.message)
    end

    def members(org)
      org.users.to_a
    end

    def both(tag)
      tag.participant_users
    end

    def org_context(user, subject)
      tag = subject.is_a?(Tag) ? subject : nil
      if tag
        return tag.sender_org if user.member_of?(tag.sender_org)
        return tag.receiver_org if user.member_of?(tag.receiver_org)
      end
      user.orgs.first
    end

    def tag_url(tag)
      Rails.application.routes.url_helpers.tag_url(tag, host: default_host)
    end

    def default_host
      Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost"
    end

    def fmt(value)
      value.nil? ? "—" : ActiveSupport::NumberHelper.number_to_delimited(value.to_i)
    end
  end
end
