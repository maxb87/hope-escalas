class ScaleResponsePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.email == "admin@admin.com"
        scope.includes(:patient, :psychometric_scale, :scale_request).recent
      elsif user.account_type == "Professional"
        # Permitir acesso a todas as respostas para todos os profissionais
        scope.includes(:patient, :psychometric_scale, :scale_request).recent
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
    user.account_type == "Professional" ||  # Qualquer profissional pode ver qualquer resposta
    (user.account_type == "Patient" && record.patient == user.account)
  end

  def create?
    return true if user.email == "admin@admin.com"
    # Permite criar resposta se:
    # 1. Usuário é paciente E a resposta pertence ao paciente logado
    # 2. OU usuário é profissional (qualquer profissional pode criar)
    if user.account_type == "Patient"
      record.patient == user.account
    elsif user.account_type == "Professional"
      true  # Qualquer profissional pode criar respostas
    else
      false
    end
  end

  def interpretation?
    # Profissionais e administradores podem acessar interpretação de qualquer resposta
    user.email == "admin@admin.com" ||
    user.account_type == "Professional"  # Qualquer profissional pode acessar interpretações
  end

  def update?
    false # Respostas não podem ser editadas após criadas
  end

  def destroy?
    # Profissionais e administradores podem descartar qualquer escala
    user.email == "admin@admin.com" ||
    user.account_type == "Professional"  # Qualquer profissional pode descartar qualquer escala
  end
end
