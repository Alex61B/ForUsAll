class UsersController < ApplicationController
  before_action :set_user

  def show
    authorize @user
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    permitted = user_params
    permitted.delete(:role) unless current_user.admin?
    if @user.update(permitted)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :department_id, :manager_id)
  end
end
