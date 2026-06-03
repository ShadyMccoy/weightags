class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :org
  belongs_to :subject, polymorphic: true, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end
end
