class ScaleRequestPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.email == "admin@admin.com"
        scope.includes(:patient, :professional, :psychometric_scale).recent
      elsif user.account_type == "Professional"
        # Permitir acesso a todas as solicitações para todos os profissionais
        scope.includes(:patient, :professional, :psychometric_scale).recent
      elsif user.account_type == "Patient"
        scope.where(patient: user.account).includes(:professional, :psychometric_scale).recent
      else
        scope.none
      end
    end
  end

  def index?
    user.email == "admin@admin.com" || user.account_type == "Professional" || user.account_type == "Patient"
  end

  # Permitir autorizar coleções em actions como pending/completed/cancelled
  def pending?
    index?
  end

  def completed?
    index?
  end

  def cancelled?
    index?
  end

  def show?
    user.email == "admin@admin.com" ||
    user.account_type == "Professional" ||  # Qualquer profissional pode ver qualquer solicitação
    (user.account_type == "Patient" && record.patient == user.account)
  end

  def create?
    user.email == "admin@admin.com" || user.account_type == "Professional"
  end

  def update?
    user.email == "admin@admin.com" ||
    user.account_type == "Professional"  # Qualquer profissional pode atualizar qualquer solicitação
  end

  def destroy?
    user.email == "admin@admin.com" ||
    user.account_type == "Professional"  # Qualquer profissional pode deletar qualquer solicitação
  end

  def cancel?
    user.email == "admin@admin.com" ||
    user.account_type == "Professional"  # Qualquer profissional pode cancelar qualquer solicitação
  end

  def respond?
    # Permite responder se:
    # 1. Usuário é paciente E a solicitação pertence ao paciente logado
    # 2. OU usuário é profissional (qualquer profissional pode responder)
    # 3. A solicitação está pendente (não foi completada, cancelada ou expirada)
    # 4. Ainda não existe uma resposta para esta solicitação
    return false unless record.pending? && record.scale_response.nil?

    return true if user.email == "admin@admin.com"

    if user.account_type == "Patient"
      record.patient == user.account
    elsif user.account_type == "Professional"
      true  # Qualquer profissional pode responder qualquer solicitação
    else
      false
    end
  end
end
