require "digest"

# An API credential for the headless ingest channel. Org-owned and tied to the
# user who minted it, so weighs posted over the API attribute to a real person in
# the audit log. Only the digest is stored; the plaintext is returned once.
class ApiKey < ApplicationRecord
  belongs_to :org
  belongs_to :user

  # Least-privilege: a read_only key for status-sync pulls, a read_write key for
  # uploading weighs. Stored as strings so the values read plainly in audit/logs.
  enum :scope, { read_only: "read_only", read_write: "read_write" }, default: :read_write

  validates :name, presence: true

  scope :active, -> { where(revoked_at: nil) }

  PREFIX = "wt_".freeze       # secret token prefix
  ID_PREFIX = "wtk_".freeze   # non-secret key-id prefix

  # Mint a key. Returns [api_key, plaintext_token]; the plaintext is shown once.
  def self.issue!(org:, user:, name:, scope: :read_write)
    raw = "#{PREFIX}#{SecureRandom.urlsafe_base64(32)}"
    key = create!(org: org, user: user, scope: scope,
      name: name.to_s.strip.presence || "API key",
      public_id: "#{ID_PREFIX}#{SecureRandom.hex(8)}",
      token_digest: digest(raw), token_last4: raw.last(4))
    [ key, raw ]
  end

  # Resolve a presented bearer token to a live key, or nil.
  def self.authenticate(raw)
    return nil if raw.blank?
    active.find_by(token_digest: digest(raw))
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw.to_s)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def can_write?
    read_write?
  end

  def scope_label
    read_only? ? "Read-only" : "Read & write"
  end

  # Touched on every authenticated request; column update skips validations and
  # the audit-irrelevant updated_at churn.
  def mark_used!
    update_column(:last_used_at, Time.current)
  end
end
