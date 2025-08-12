class PatientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      # Admin ou profissional enxergam todos os pacientes
      return scope.all if user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)

      # Paciente enxerga apenas a si mesmo
      if user.account_type == "Patient" && user.account_id.present?
        scope.where(id: user.account_id)
      else
        scope.none
      end
    end
  end

  def index?
    # Listagem completa de pacientes apenas para admin/profissional
    user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)
  end

  def show?
    return true if user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)
    return user.account_id == record.id if user.account_type == "Patient" && user.account_id.present?
    false
  end

  def create?
    user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)
  end

  def update?
    return true if user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)
    # Paciente pode editar o próprio perfil
    user.account_type == "Patient" && user.account_id.present? && user.account_id == record.id
  end

  def destroy?
    user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?)
  end
end
