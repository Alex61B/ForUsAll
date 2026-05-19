class Api::V1::TimeOffRequestsController < Api::V1::BaseController
  before_action :set_request, only: [ :show, :update, :destroy, :approve, :deny, :cancel ]

  def index
    requests = policy_scope(TimeOffRequest)
                 .by_status(params[:status])
                 .by_leave_type(params[:leave_type])
                 .order(created_at: :desc)
                 .page(params[:page]).per(20)
    render_jsonapi(TimeOffRequestSerializer, requests, { meta: { total: requests.total_count } })
  end

  def show
    authorize @request
    render_jsonapi(TimeOffRequestSerializer, @request)
  end

  def create
    @request = current_user.time_off_requests.build(request_params)
    authorize @request
    if @request.save
      NotifyManagerJob.perform_later(@request.id)
      render_jsonapi(TimeOffRequestSerializer, @request, { status: :created })
    else
      render_jsonapi_errors(@request)
    end
  end

  def update
    authorize @request
    if @request.update(request_params)
      render_jsonapi(TimeOffRequestSerializer, @request)
    else
      render_jsonapi_errors(@request)
    end
  end

  def destroy
    authorize @request
    @request.update!(status: :cancelled)
    NotifyRequesterJob.perform_later(@request.id, "cancelled")
    render json: {}, status: :no_content
  end

  def approve
    authorize @request, :approve?
    @request.update!(status: :approved, reviewed_by: current_user, reviewed_at: Time.current)
    create_or_update_approval(:approved)
    NotifyRequesterJob.perform_later(@request.id, "approved")
    render_jsonapi(TimeOffRequestSerializer, @request)
  rescue ActiveRecord::RecordInvalid => e
    render_jsonapi_errors(@request)
  end

  def deny
    authorize @request, :deny?
    @request.update!(status: :denied, reviewed_by: current_user, reviewed_at: Time.current)
    create_or_update_approval(:denied)
    NotifyRequesterJob.perform_later(@request.id, "denied")
    render_jsonapi(TimeOffRequestSerializer, @request)
  rescue ActiveRecord::RecordInvalid => e
    render_jsonapi_errors(@request)
  end

  def cancel
    authorize @request, :cancel?
    @request.update!(status: :cancelled)
    NotifyRequesterJob.perform_later(@request.id, "cancelled")
    render_jsonapi(TimeOffRequestSerializer, @request)
  rescue ActiveRecord::RecordInvalid => e
    render_jsonapi_errors(@request)
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
