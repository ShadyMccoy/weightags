require "digest"

# An API credential for the headless ingest channel. Org-owned and tied to the
# user who minted it, so weighs posted over the API attribute to a real person in
# the audit log. Only the digest is stored; the plaintext is returned once.
class ApiKey < ApplicationRecord
  belongs_to :org
  belongs_to :user

  # Least-privilege: a read_only key for status-sync pulls, a read_write key for
  # uploading weighs. Stored as strings so the values read plainly in audit/logs.
  # Defaults to the weaker scope — an unstated scope is an undecided one, and the
  # safe reading of undecided is "cannot post weighs".
  enum :scope, { read_only: "read_only", read_write: "read_write" }, default: :read_only

  validates :name, presence: true

  scope :active, -> { where(revoked_at: nil) }

  # A distinctive, greppable secret prefix: it makes a leaked token recognisable
  # in code search and is what a secret-scanning partner program would register.
  # `_live_` leaves room for a `wt_test_` sandbox without a format change. Keys
  # minted before this prefix (plain `wt_`) still authenticate — the prefix is
  # never parsed, only the digest is looked up.
  PREFIX = "wt_live_".freeze
  ID_PREFIX = "wtk_".freeze   # non-secret key-id prefix

  # How stale last_used_at is allowed to get. Without this a hot integration
  # turns every GET into an UPDATE; a minute's resolution is all the dashboard
  # column is read at.
  USED_AT_RESOLUTION = 1.minute

  # Mint a key. Returns [api_key, plaintext_token]; the plaintext is shown once.
  # 43 base58 characters ≈ 252 bits from a CSPRNG — no part of the token derives
  # from org or user data, and base58 drops the glyphs people mis-transcribe.
  def self.issue!(org:, user:, name:, scope: :read_only)
    raw = "#{PREFIX}#{SecureRandom.base58(43)}"
    key = create!(org: org, user: user, scope: scope,
      name: name.to_s.strip.presence || "API key",
      public_id: "#{ID_PREFIX}#{SecureRandom.hex(8)}",
      token_digest: digest(raw))
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

  # Touched on every authenticated request, debounced to USED_AT_RESOLUTION so a
  # polling integration doesn't make a write out of every read. Column update
  # skips validations and the audit-irrelevant updated_at churn.
  def mark_used!
    return if last_used_at && last_used_at > USED_AT_RESOLUTION.ago
    update_column(:last_used_at, Time.current)
  end
end
