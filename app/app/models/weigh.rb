class Weigh < ApplicationRecord
  belongs_to :org
  belongs_to :counterparty_org, class_name: "Org"
  belongs_to :tag, optional: true
  belongs_to :recorded_by, class_name: "User", optional: true

  enum :side, { sender: 0, receiver: 1 }

  before_validation :derive_net

  validates :bol, presence: true
  validates :side, presence: true
  validates :gross, :tare, :net,
    numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :moisture,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :bol, uniqueness: { scope: [ :org_id, :counterparty_org_id ],
    message: "already has a tag for this partner" }

  scope :unpaired, -> { where(tag_id: nil) }

  def recorded_ref = bol

  private

  def derive_net
    self.net = gross - tare if net.blank? && gross.present? && tare.present?
  end
end
