module Tags
  MAX_BOL_DISTANCE = 2
  NET_CORROBORATION_FRACTION = 0.02

  class Suggester
    def self.scan(weigh)
      new(weigh).scan
    end

    def initialize(weigh)
      @weigh = weigh
    end

    def scan
      return [] unless @weigh.tag&.one_sided?

      candidates.filter_map do |other|
        distance = Suggester.levenshtein(@weigh.bol, other.bol)
        next if distance.zero? || distance > MAX_BOL_DISTANCE
        reasons = corroborations(@weigh, other)
        next if reasons.empty?
        build_suggestion(other, distance, reasons)
      end
    end

    private

    def candidates
      Weigh.where(side: opposite_side, org_id: @weigh.counterparty_org_id, counterparty_org_id: @weigh.org_id)
        .where.not(bol: @weigh.bol)
        .includes(:tag)
        .select { |t| t.tag&.one_sided? }
    end

    def opposite_side
      @weigh.sender? ? :receiver : :sender
    end

    def corroborations(a, b)
      reasons = []
      reasons << "ship date" if a.ship_date && a.ship_date == b.ship_date
      reasons << "truck" if a.truck.present? && a.truck.casecmp?(b.truck.to_s)
      reasons << "weight" if nets_close?(a.net, b.net)
      reasons
    end

    def nets_close?(x, y)
      return false if x.nil? || y.nil? || x.zero?
      ((x - y).abs / x) <= NET_CORROBORATION_FRACTION
    end

    def build_suggestion(other, distance, reasons)
      sender, receiver = @weigh.sender? ? [ @weigh, other ] : [ other, @weigh ]
      attrs = { sender_weigh: sender, receiver_weigh: receiver,
                sender_org: sender.org, receiver_org: receiver.org,
                bol_sender: sender.bol, bol_receiver: receiver.bol,
                distance: distance, corroboration: reasons.join(", ") }
      suggestion = PairingSuggestion.where(sender_weigh: sender, receiver_weigh: receiver).first
      return suggestion if suggestion

      suggestion = PairingSuggestion.create!(attrs)
      AuditEvent.record!(action: "suggestion.created", subject: sender.tag, bol: sender.bol,
        metadata: { matched_bol: receiver.bol, distance: distance, corroboration: reasons.join(", ") })
      suggestion
    end

    def self.levenshtein(a, b)
      a = a.to_s.downcase
      b = b.to_s.downcase
      return b.length if a.empty?
      return a.length if b.empty?

      prev = (0..b.length).to_a
      a.each_char.with_index do |ca, i|
        curr = [ i + 1 ]
        b.each_char.with_index do |cb, j|
          cost = ca == cb ? 0 : 1
          curr << [ curr[j] + 1, prev[j + 1] + 1, prev[j] + cost ].min
        end
        prev = curr
      end
      prev.last
    end
  end
end
