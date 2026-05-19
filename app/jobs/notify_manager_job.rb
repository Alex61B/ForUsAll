class NotifyManagerJob < ApplicationJob
  queue_as :default

  def perform(time_off_request_id)
    request = TimeOffRequest.find(time_off_request_id)
    TimeOffRequestMailer.request_submitted(request).deliver_now
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("NotifyManagerJob: TimeOffRequest #{time_off_request_id} not found")
  end
end
