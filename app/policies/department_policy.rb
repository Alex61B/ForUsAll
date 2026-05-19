class DepartmentPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = user.admin?
  def update? = user.admin?
  def destroy? = user.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
