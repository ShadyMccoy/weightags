class AuditEvent < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :actor_org, class_name: "Org", optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, presence: true
  validates :occurred_at, presence: true

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }

  before_update  { raise ActiveRecord::ReadOnlyRecord, "audit_events are append-only" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "audit_events are append-only" }

  def self.record!(action:, subject: nil, user: nil, actor_org: nil, bol: nil, metadata: {})
    create!(
      action: action,
      subject: subject,
      user: user,
      actor_org: actor_org,
      bol: bol || subject.try(:bol),
      metadata: metadata,
      occurred_at: Time.current
    )
  end

  def actor_label
    return "WeighTags" if user.nil?
    org = actor_org&.name
    org ? "#{user.display_name} (#{org})" : user.display_name
  end
end
