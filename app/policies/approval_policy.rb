class ApprovalPolicy < ApplicationPolicy
  def index? = user.admin? || user.manager?
  def show?  = user.admin? || user.manager? || record.time_off_request.user == user

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.manager?
        direct_report_ids = User.where(manager_id: user.id).pluck(:id)
        scope.joins(:time_off_request).where(time_off_requests: { user_id: [ user.id ] + direct_report_ids })
      else
        scope.joins(:time_off_request).where(time_off_requests: { user_id: user.id })
      end
    end
  end
end
