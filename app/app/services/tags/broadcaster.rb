module Tags
  class Broadcaster
    def self.refresh(tag)
      return unless tag
      [ tag.sender_org_id, tag.receiver_org_id ].uniq.each do |org_id|
        Turbo::StreamsChannel.broadcast_refresh_to("org_#{org_id}_loads")
      end
    rescue => e
      Rails.logger.error("[Tags::Broadcaster] #{e.class}: #{e.message}")
    end
  end
end
