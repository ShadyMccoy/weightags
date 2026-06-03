module TagsHelper
  ACTIVITY_LABELS = {
    "weigh.posted"            => "Weigh posted",
    "tag.paired"           => "Paired",
    "suggestion.created"    => "Match suggested",
    "suggestion.confirmed_by" => "Match confirmed (one side)",
    "suggestion.confirmed"  => "Match confirmed",
    "suggestion.rejected"   => "Match dismissed",
    "tag.merged"            => "Merged shipments",
    "tag.split"             => "Separated weigh",
    "tag.accepted"         => "Accepted",
    "tag.disputed"         => "Disputed",
    "tag.compromise_proposed" => "Compromise proposed",
    "tag.compromise_accepted" => "Compromise accepted",
    "weigh.edited"            => "Weigh edited",
    "tag.reopened"         => "Re-review",
    "tag.reminder_sent"    => "Reminder sent",
    "tag.auto_accepted"    => "Auto-accepted",
    "tag.note_added"       => "Note added",
    "tag.invoiced"         => "Marked invoiced",
    "invoice_batch.created" => "Invoice batch created",
    "csv.imported"          => "CSV imported",
    "org.created"           => "Organization created"
  }.freeze

  def activity_label(action)
    ACTIVITY_LABELS.fetch(action) { action.tr(".", " ").humanize }
  end

  def activity_details(event)
    m = event.metadata || {}
    case event.action
    when "weigh.posted"
      "#{m['side']&.capitalize} side, net #{format_lb(m['net'])}"
    when "tag.paired"
      within = ActiveModel::Type::Boolean.new.cast(m["within_tolerance"])
      "#{within ? 'Within tolerance' : 'Exceeds tolerance'} — auto-#{within ? 'matched' : 'flagged for review'}"
    when "tag.accepted"
      "Adopted #{m['accepted_side']} values"
    when "tag.disputed"
      [ m["reason"], m["notes"].presence ].compact.join(" — ")
    when "tag.compromise_proposed"
      c = m["canonical"] || {}
      "Proposed net #{format_lb(c['net'])}"
    when "weigh.edited"
      before, after = m["before"] || {}, m["after"] || {}
      "Net #{format_lb(before['net'])} → #{format_lb(after['net'])} · #{m['reason']}"
    when "tag.reminder_sent"
      "#{m['mark'] == 'final' ? 'Final' : 'Halfway'} reminder — window closes #{m['due_at'] ? Time.zone.parse(m['due_at']).strftime('%b %-d') : ''}"
    when "tag.auto_accepted"
      "Window closed uncontested — defaulted to sender, net #{format_lb(m['net'])}"
    when "tag.note_added"
      m["body"]
    when "tag.invoiced"
      "Linked to external invoice #{m['invoice_number']}"
    when "csv.imported"
      "#{m['rows']} rows from #{m['partner']}"
    else
      ""
    end
  end

  private

  def format_lb(value)
    return "—" if value.blank?
    number_with_delimiter(value.to_f.to_i)
  end
end
