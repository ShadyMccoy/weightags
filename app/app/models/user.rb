class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :notifications, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :active_memberships, -> { active }, class_name: "Membership"
  has_many :orgs, through: :active_memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true
  validates :name, presence: true

  def display_name
    name.presence || email_address
  end

  def default_org
    orgs.order(:created_at).first
  end

  def accessible_org_ids
    active_memberships.pluck(:org_id)
  end

  def member_of?(org)
    active_memberships.exists?(org: org)
  end

  def admin_of?(org)
    active_memberships.exists?(org: org, role: :admin)
  end
end
