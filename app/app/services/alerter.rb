class Alerter
  KINDS = %w[
    auto_accept_misfire
    clock_anomaly
    notification_delivery_failure
    csv_ingest_error
  ].freeze

  def self.raise!(kind:, message:, **context)
    Rails.logger.error("[ALERT:#{kind}] #{message} #{context.to_json}")
    OperationalAlert.create!(
      kind: kind, message: message, context: context, created_at: Time.current
    )
  rescue => e
    Rails.logger.error("[Alerter] failed to record alert: #{e.class}: #{e.message}")
    nil
  end
end
