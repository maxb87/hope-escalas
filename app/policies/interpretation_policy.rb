# frozen_string_literal: true

class InterpretationPolicy < ApplicationPolicy
  def srs2_interpretation?
    # Verificar se o usuário tem acesso à resposta da escala
    return true if user.email == "admin@admin.com"
    
    if user.account_type == "Professional"
      # Profissional pode ver interpretações de suas próprias solicitações
      record.scale_request.professional == user.account
    elsif user.account_type == "Patient"
      # Paciente pode ver suas próprias interpretações
      record.patient == user.account
    else
      false
    end
  end
end
