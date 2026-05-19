class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [ :show, :update ]

  def index
    users = policy_scope(User).by_name.page(params[:page]).per(25)
    render_jsonapi(UserSerializer, users, { meta: { total: users.total_count } })
  end

  def show
    authorize @user
    render_jsonapi(UserSerializer, @user)
  end

  def update
    authorize @user
    permitted = user_params
    permitted.delete(:role) unless current_user.admin?
    if @user.update(permitted)
      render_jsonapi(UserSerializer, @user)
    else
      render_jsonapi_errors(@user)
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :department_id, :manager_id, :role)
  end
end
