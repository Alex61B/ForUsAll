class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    unless current_user&.admin?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Admin access required." }
        format.json { render json: { errors: [ { title: "Forbidden", detail: "Admin access required." } ] }, status: :forbidden }
      end
    end
  end
end
