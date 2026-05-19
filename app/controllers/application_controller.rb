class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "You are not authorized to perform this action." }
      format.json { render json: { errors: [ { title: "Forbidden", detail: "You are not authorized." } ] }, status: :forbidden }
    end
  end
end
