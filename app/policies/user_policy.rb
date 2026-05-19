class UserPolicy < ApplicationPolicy
  def index?  = user.admin?
  def show?   = user.admin? || record == user
  def update? = user.admin? || record == user

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.all : scope.where(id: user.id)
    end
  end
end
