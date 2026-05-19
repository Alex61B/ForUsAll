class TimeOffRequestPolicy < ApplicationPolicy
  def index?  = true
  def show?   = user.admin? || record.user == user || manages_requester?
  def create? = true
  def update? = record.pending? && (record.user == user || user.admin?)
  def destroy? = record.pending? && (record.user == user || user.admin?)

  def approve? = !record.approved? && (user.admin? || manages_requester?)
  def deny?    = !record.denied?   && (user.admin? || manages_requester?)
  def cancel?  = record.pending?   && (record.user == user || user.admin? || manages_requester?)

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.visible_to(user)
  end

  private

  def manages_requester?
    user.manager? && record.user.manager_id == user.id
  end
end
