class Tag < ApplicationRecord
  belongs_to :sender_org, class_name: "Org"
  belongs_to :receiver_org, class_name: "Org"
  belongs_to :resolved_by, class_name: "User", optional: true
  belongs_to :invoice_batch, optional: true

  has_many :weighs, dependent: :nullify
  has_one :sender_weigh,   -> { where(side: :sender) },   class_name: "Weigh"
  has_one :receiver_weigh, -> { where(side: :receiver) }, class_name: "Weigh"

  has_many :audit_events, as: :subject

  enum :state, {
    pending: 0,
    matched: 1,
    review: 2,
    disputed: 3,
    compromise_proposed: 4,
    resolved: 5,
    invoiced: 6
  }

  enum :resolution, {
    clean_match: 0,
    accepted_sender: 1,
    accepted_receiver: 2,
    compromise: 3,
    auto_accepted: 4
  }, prefix: true

  scope :for_org, ->(org) {
    where(sender_org_id: org.id).or(where(receiver_org_id: org.id))
  }

  scope :closed_unbilled, -> { where(state: [ states[:resolved], states[:matched] ], invoice_batch_id: nil) }
  scope :billed, -> { where.not(invoice_batch_id: nil) }

  COMPARED_METRICS = %i[gross tare net moisture].freeze

  def reset_weighs!
    %i[weighs sender_weigh receiver_weigh].each { |a| association(a).reset }
    self
  end

  # Activity for this shipment spans events recorded against the Tag itself
  # (state transitions) and against its Weighs (e.g. weigh.edited, which carries
  # the before/after detail). The bare `audit_events` association only covers the
  # Tag-subject half, so the panel must union in the weigh-subject events too.
  def related_audit_events
    AuditEvent
      .where(subject_type: "Tag", subject_id: id)
      .or(AuditEvent.where(subject_type: "Weigh", subject_id: weighs.ids))
  end

  def both_sided?
    sender_weigh.present? && receiver_weigh.present?
  end

  def one_sided?
    !both_sided?
  end

  def awaiting_side
    return nil if both_sided?
    sender_weigh.nil? ? :sender : :receiver
  end

  def delta(metric)
    s = sender_weigh&.public_send(metric)
    r = receiver_weigh&.public_send(metric)
    return nil if s.nil? || r.nil?
    r - s
  end

  def net_delta
    delta(:net)
  end

  def net_delta_fraction
    s = sender_weigh&.net
    d = net_delta
    return nil if d.nil? || s.nil? || s.zero?
    d / s
  end

  def net_delta_percent
    f = net_delta_fraction
    (f * 100).round(2) if f
  end

  def tolerance_fraction
    BigDecimal(tolerance_bps) / 10_000
  end

  def within_tolerance?
    f = net_delta_fraction
    f.present? && f.abs <= tolerance_fraction
  end

  def exceeds_tolerance?
    f = net_delta_fraction
    f.present? && f.abs > tolerance_fraction
  end

  def adopt_canonical_from(weigh)
    assign_attributes(canonical_gross: weigh.gross, canonical_tare: weigh.tare, canonical_net: weigh.net)
  end

  def reproject(force: false)
    return self if !force && (disputed? || compromise_proposed? || final?)

    if both_sided?
      if within_tolerance?
        adopt_canonical_from(sender_weigh)
        assign_attributes(state: :matched, resolution: :clean_match, resolved_at: resolved_at || Time.current)
      else
        assign_attributes(state: :review, resolution: nil, resolved_at: nil,
          canonical_gross: nil, canonical_tare: nil, canonical_net: nil)
      end
    else
      assign_attributes(state: :pending, resolution: nil)
    end
    self
  end

  def discard_if_empty!
    destroy! if weighs.reload.empty?
  end

  def closed?
    resolved? || matched? || invoiced?
  end

  def final?
    resolved? || invoiced?
  end

  def can_accept?
    both_sided? && (review? || disputed?)
  end

  def can_dispute?
    both_sided? && (matched? || review? || compromise_proposed?)
  end

  def can_propose_compromise?
    both_sided? && (review? || disputed?)
  end

  def can_accept_compromise?
    compromise_proposed?
  end

  def can_edit_tag?(org)
    !final? && weigh_for(org).present?
  end

  def participant_orgs
    [ sender_org, receiver_org ].uniq
  end

  def participant_users
    participant_orgs.flat_map(&:users).uniq
  end

  def counterparty_of(org)
    org.id == sender_org_id ? receiver_org : sender_org
  end

  def side_of(org)
    return :sender if org.id == sender_org_id
    return :receiver if org.id == receiver_org_id
    nil
  end

  def weigh_for(org)
    side_of(org) == :sender ? sender_weigh : receiver_weigh
  end
end
