class Partnership < ApplicationRecord
  belongs_to :org
  belongs_to :counterparty_org, class_name: "Org"

  validates :tolerance_bps, numericality: { greater_than_or_equal_to: 0 }
  validates :dispute_window_days, numericality: { greater_than: 0 }
  validates :org_id, uniqueness: { scope: :counterparty_org_id }

  def tolerance_fraction
    tolerance_bps / 10_000.0
  end

  def tolerance_percent
    (tolerance_fraction * 100).round(2)
  end

  def self.settings_for(org:, counterparty:)
    find_by(org: org, counterparty_org: counterparty) ||
      new(org: org, counterparty_org: counterparty)
  end

  def self.ensure!(org:, counterparty:, invite_email: nil)
    find_or_create_by!(org: org, counterparty_org: counterparty) do |p|
      p.invite_email = invite_email
    end
    find_or_create_by!(org: counterparty, counterparty_org: org)
  end
end
