class ProfessionalPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)
      scope.none
    end
  end

  def index?
    user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)
  end

  def show?
    index?
  end

  def create?
    index?
  end

  def update?
    # Pacientes não podem editar profissionais; somente admin/profissional
    index?
  end

  def destroy?
    index?
  end
end
