class DisputeClockJob < ApplicationJob
  queue_as :default

  def perform
    result = Tags::Clock.process_due
    if result[:reminded].positive? || result[:auto_accepted].positive?
      Rails.logger.info("[DisputeClockJob] reminded=#{result[:reminded]} auto_accepted=#{result[:auto_accepted]}")
    end
    result
  end
end
