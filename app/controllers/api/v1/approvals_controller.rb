class Api::V1::ApprovalsController < Api::V1::BaseController
  before_action :set_approval, only: [ :show ]

  def index
    approvals = policy_scope(Approval).includes(:time_off_request, :approver)
                                      .order(created_at: :desc)
                                      .page(params[:page]).per(25)
    render_jsonapi(ApprovalSerializer, approvals, { meta: { total: approvals.total_count } })
  end

  def show
    authorize @approval
    render_jsonapi(ApprovalSerializer, @approval)
  end

  private

  def set_approval
    @approval = Approval.find(params[:id])
  end
end
