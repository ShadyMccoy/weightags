class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :org

  enum :role, { member: 0, admin: 1 }

  scope :active, -> { where(ended_at: nil) }
  scope :ended, -> { where.not(ended_at: nil) }

  before_validation :set_joined_at, on: :create

  validates :user_id, uniqueness: { scope: :org_id, conditions: -> { active },
    message: "already has an active membership in this org" }, if: :active?

  def active?
    ended_at.nil?
  end

  def end!(at: Time.current)
    update!(ended_at: at)
  end

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end
end
