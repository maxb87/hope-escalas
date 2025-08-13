class PsychometricScalePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.email == "admin@admin.com" || user.account_type == "Professional"
        scope.active.ordered
      else
        scope.none
      end
    end
  end

  def index?
    user.email == "admin@admin.com" || user.account_type == "Professional"
  end

  def show?
    user.email == "admin@admin.com" || user.account_type == "Professional"
  end

  def create?
    user.email == "admin@admin.com"
  end

  def update?
    user.email == "admin@admin.com"
  end

  def destroy?
    user.email == "admin@admin.com"
  end
end
