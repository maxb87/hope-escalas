class ScaleResponsePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.email == "admin@admin.com"
        scope.includes(:patient, :psychometric_scale, :scale_request).recent
      elsif user.account_type == "Professional"
        scope.joins(:scale_request).where(scale_requests: { professional: user.account })
             .includes(:patient, :psychometric_scale).recent
      elsif user.account_type == "Patient"
        scope.where(patient: user.account).includes(:psychometric_scale, :scale_request).recent
      else
        scope.none
      end
    end
  end

  def index?
    user.email == "admin@admin.com" || user.account_type == "Professional" || user.account_type == "Patient"
  end

  def show?
    user.email == "admin@admin.com" || 
    (user.account_type == "Professional" && record.scale_request.professional == user.account) ||
    (user.account_type == "Patient" && record.patient == user.account)
  end

  def create?
    user.account_type == "Patient" && record.patient == user.account
  end

  def update?
    false # Respostas não podem ser editadas após criadas
  end

  def destroy?
    false # Respostas não podem ser excluídas
  end
end
