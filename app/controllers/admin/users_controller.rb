class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :edit, :update ]

  def index
    @users = User.includes(:department, :manager).by_name.page(params[:page]).per(25)
  end

  def show; end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = params.require(:user).permit(:first_name, :last_name, :email, :department_id, :manager_id)
    role = params.dig(:user, :role)
    permitted[:role] = role if role.present? && User.roles.key?(role.to_s)
    permitted
  end
end
