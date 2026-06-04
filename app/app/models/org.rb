class Org < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :active_memberships, -> { active }, class_name: "Membership"
  has_many :users, through: :active_memberships

  has_many :partnerships, dependent: :destroy
  has_many :partner_orgs, through: :partnerships, source: :counterparty_org

  has_many :weighs, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  has_many :sent_tags, class_name: "Tag", foreign_key: :sender_org_id, dependent: :destroy
  has_many :received_tags, class_name: "Tag", foreign_key: :receiver_org_id, dependent: :destroy

  before_validation :assign_slug, on: :create

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :claimed, -> { where(claimed: true) }
  scope :ghost, -> { where(claimed: false) }

  def self.establish!(name:, admin:)
    transaction do
      org = create!(name: name)
      org.memberships.create!(user: admin, role: :admin)
      AuditEvent.record!(action: "org.created", subject: org, user: admin,
        actor_org: org, metadata: { name: org.name })
      org
    end
  end

  def claim!(by:)
    transaction do
      memberships.create!(user: by, role: :admin)
      update!(claimed: true)
      AuditEvent.record!(action: "org.claimed", subject: self, user: by,
        actor_org: self, metadata: { email: by.email_address })
      self
    end
  end

  generates_token_for :claim, expires_in: 30.days

  def domain_verified?
    domain_verified_at.present?
  end

  def expected_txt_record
    "weightags-verification=#{domain_verification_token}"
  end

  def assign_domain!(domain)
    domain = domain.to_s.strip.downcase.presence
    update!(
      domain: domain,
      domain_verified_at: nil,
      domain_verification_token: (domain ? SecureRandom.hex(16) : nil)
    )
  end

  def mark_domain_verified!
    update!(domain_verified_at: Time.current)
  end

  def tags
    Tag.for_org(self)
  end

  def admins
    users.merge(Membership.admin)
  end

  def sole_admin?
    active_memberships.admin.count == 1
  end

  private

  def assign_slug
    return if slug.present?

    base = name.to_s.parameterize.presence || "org"
    candidate = base
    n = 1
    while Org.where(slug: candidate).where.not(id: id).exists?
      n += 1
      candidate = "#{base}-#{n}"
    end
    self.slug = candidate
  end
end
