class StatusPillComponent < ViewComponent::Base
  COLORS = {
    "draft"     => "bg-status-draft",
    "pending"   => "bg-status-pending",
    "matched"   => "bg-status-matched",
    "review"    => "bg-status-review",
    "disputed"  => "bg-status-disputed",
    "compromise_proposed" => "bg-status-pending",
    "resolved"  => "bg-status-resolved",
    "invoiced"  => "bg-status-invoiced"
  }.freeze

  LABELS = {
    "draft"     => "Draft",
    "pending"   => "Pending",
    "matched"   => "Matched",
    "review"    => "Review",
    "disputed"  => "Disputed",
    "compromise_proposed" => "Compromise proposed",
    "resolved"  => "Resolved",
    "invoiced"  => "Invoiced"
  }.freeze

  def initialize(status:, label: nil)
    @status = status.to_s
    @label = label
  end

  def self.for_tag(tag)
    label = if tag.pending?
      "Awaiting #{tag.awaiting_side}"
    end
    new(status: tag.state, label: label)
  end

  def call
    content_tag :span, (@label || LABELS.fetch(@status, @status.humanize)),
      class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium text-white #{COLORS.fetch(@status, 'bg-status-draft')}"
  end
end
