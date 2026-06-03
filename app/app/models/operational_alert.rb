class OperationalAlert < ApplicationRecord
  validates :kind, :message, presence: true
  scope :recent_first, -> { order(created_at: :desc) }
end
