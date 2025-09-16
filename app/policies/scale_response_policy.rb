class ScaleResponsePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.email == "admin@admin.com"
        scope.includes(:patient, :psychometric_scale, :scale_request).recent
      elsif user.account_type == "Professional"
        scope.joins(:scale_request).where(scale_requests: { professional: user.account })
             .includes(:patient, :psychometric_scale).recent
      else
        scope.none
      end
    end
  end

  def index?
    user.email == "admin@admin.com" || user.account_type == "Professional"
  end

  def show?
    user.email == "admin@admin.com" ||
    (user.account_type == "Professional" && record.scale_request.professional == user.account) ||
    (user.account_type == "Patient" && record.patient == user.account)
  end

  def create?
    return true if user.email == "admin@admin.com"
    # Permite criar resposta se:
    # 1. Usuário é paciente E a resposta pertence ao paciente logado
    # 2. OU usuário é profissional E a solicitação pertence ao profissional logado
    if user.account_type == "Patient"
      record.patient == user.account
    elsif user.account_type == "Professional"
      record.scale_request.professional == user.account
    else
      false
    end
  end

  def interpretation?
    # Apenas profissionais e administradores podem acessar a interpretação
    user.email == "admin@admin.com" || 
    (user.account_type == "Professional" && record.scale_request.professional == user.account)
  end

  def update?
    false # Respostas não podem ser editadas após criadas
  end

  def destroy?
    # Apenas profissionais e administradores podem descartar escalas
    user.email == "admin@admin.com" ||
    (user.account_type == "Professional" && record.scale_request.professional == user.account)
  end
end
