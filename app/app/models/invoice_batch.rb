class InvoiceBatch < ApplicationRecord
  has_secure_token :token

  belongs_to :sender_org, class_name: "Org"
  belongs_to :receiver_org, class_name: "Org"
  belongs_to :created_by, class_name: "User", optional: true

  has_many :tags, dependent: :nullify

  validates :external_invoice_number, presence: true

  scope :for_org, ->(org) {
    where(sender_org_id: org.id).or(where(receiver_org_id: org.id))
  }

  def total_net
    tags.sum { |l| l.canonical_net || l.sender_weigh&.net || 0 }
  end

  def load_count
    tags.size
  end
end
