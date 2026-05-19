class Admin::TimeOffRequestsController < Admin::BaseController
  def index
    @users = User.by_name
    @requests = TimeOffRequest.includes(:user, :reviewed_by)
                              .by_user(params[:user_id])
                              .by_status(params[:status])
                              .by_leave_type(params[:leave_type])
                              .order(created_at: :desc)
                              .page(params[:page]).per(25)
  end
end
