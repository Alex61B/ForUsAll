class DashboardController < ApplicationController
  def index
    @pending_count = TimeOffRequest.visible_to(current_user).pending.count
    @recent_requests = TimeOffRequest.visible_to(current_user)
                                     .order(created_at: :desc)
                                     .limit(5)
  end
end
