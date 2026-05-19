class TimeOffRequestsController < ApplicationController
  before_action :set_request, only: [ :show, :approve, :deny, :cancel ]

  def index
    @requests = policy_scope(TimeOffRequest)
                  .by_status(params[:status])
                  .by_leave_type(params[:leave_type])
                  .order(created_at: :desc)
                  .page(params[:page]).per(20)
  end

  def show
    authorize @request
  end

  def new
    @request = TimeOffRequest.new
    authorize @request
  end

  def create
    @request = current_user.time_off_requests.build(request_params)
    authorize @request
    if @request.save
      NotifyManagerJob.perform_later(@request.id)
      redirect_to time_off_requests_path, notice: "Request submitted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    authorize @request, :approve?
    @request.update!(status: :approved, reviewed_by: current_user, reviewed_at: Time.current)
    create_or_update_approval(:approved)
    NotifyRequesterJob.perform_later(@request.id, "approved")
    redirect_to time_off_request_path(@request), notice: "Request approved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to time_off_request_path(@request), alert: e.message
  end

  def deny
    authorize @request, :deny?
    @request.update!(status: :denied, reviewed_by: current_user, reviewed_at: Time.current)
    create_or_update_approval(:denied)
    NotifyRequesterJob.perform_later(@request.id, "denied")
    redirect_to time_off_request_path(@request), notice: "Request denied."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to time_off_request_path(@request), alert: e.message
  end

  def cancel
    authorize @request, :cancel?
    @request.update!(status: :cancelled)
    NotifyRequesterJob.perform_later(@request.id, "cancelled")
    redirect_to time_off_requests_path, notice: "Request cancelled."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to time_off_request_path(@request), alert: e.message
  end

  private

  def set_request
    @request = TimeOffRequest.find(params[:id])
  end

  def request_params
    params.require(:time_off_request).permit(:leave_type, :start_date, :end_date, :reason)
  end

  def create_or_update_approval(decision)
    approval = @request.approval || @request.build_approval
    approval.update!(approver: current_user, decision: decision, notes: params[:notes])
  end
end
