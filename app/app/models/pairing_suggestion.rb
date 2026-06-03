class PairingSuggestion < ApplicationRecord
  belongs_to :sender_weigh, class_name: "Weigh"
  belongs_to :receiver_weigh, class_name: "Weigh"
  belongs_to :sender_org, class_name: "Org"
  belongs_to :receiver_org, class_name: "Org"

  enum :state, { pending: 0, confirmed: 1, rejected: 2 }

  scope :open, -> { pending }

  scope :for_tags, ->(tag_ids) {
    where(sender_weigh_id: tag_ids).or(where(receiver_weigh_id: tag_ids))
  }

  def confirmed_by?(org)
    return sender_confirmed_at.present? if org.id == sender_org_id
    return receiver_confirmed_at.present? if org.id == receiver_org_id
    false
  end

  def both_confirmed?
    sender_confirmed_at.present? && receiver_confirmed_at.present?
  end

  def other_bol_for(org)
    org.id == sender_org_id ? bol_receiver : bol_sender
  end
end
