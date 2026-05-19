class NotifyRequesterJob < ApplicationJob
  queue_as :default

  def perform(time_off_request_id, decision)
    request = TimeOffRequest.find(time_off_request_id)
    case decision.to_s
    when "approved"  then TimeOffRequestMailer.request_approved(request).deliver_now
    when "denied"    then TimeOffRequestMailer.request_denied(request).deliver_now
    when "cancelled" then TimeOffRequestMailer.request_cancelled(request).deliver_now
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("NotifyRequesterJob: TimeOffRequest #{time_off_request_id} not found")
  end
end
