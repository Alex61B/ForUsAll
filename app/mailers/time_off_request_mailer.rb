class TimeOffRequestMailer < ApplicationMailer
  def request_submitted(time_off_request)
    @request = time_off_request
    @employee = @request.user
    @manager = @employee.manager
    return unless @manager&.email

    mail(to: @manager.email, subject: "New time off request from #{@employee.full_name}")
  end

  def request_approved(time_off_request)
    @request = time_off_request
    @employee = @request.user
    mail(to: @employee.email, subject: "Your time off request has been approved")
  end

  def request_denied(time_off_request)
    @request = time_off_request
    @employee = @request.user
    mail(to: @employee.email, subject: "Your time off request has been denied")
  end

  def request_cancelled(time_off_request)
    @request = time_off_request
    @employee = @request.user
    mail(to: @employee.email, subject: "Your time off request has been cancelled")
  end
end
