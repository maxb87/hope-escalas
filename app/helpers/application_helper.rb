module ApplicationHelper
  def professional_or_admin?
    current_user&.account_type == "Professional" ||
    current_user&.email == "admin@admin.com"
  end

  def patient_only?
    current_user&.account_type == "Patient"
  end

  # Helper para mostrar o status das solicitações SRS-2 de um paciente
  def srs2_status_badge_for(patient)
    return unless patient

    badges = []

    # Status do autorelato
    if patient.has_active_srs2_self_report?
      self_report = patient.active_srs2_self_report
      status_class = self_report.pending? ? "bg-warning" : "bg-success"
      status_text = self_report.pending? ? "Autorelato Pendente" : "Autorelato Concluído"
      badges << content_tag(:span, status_text, class: "badge #{status_class} me-1")
    else
      badges << content_tag(:span, "Autorelato Disponível", class: "badge bg-secondary me-1")
    end

    # Status do heterorelato
    if patient.has_active_srs2_hetero_reports?
      hetero_reports_count = patient.active_srs2_hetero_reports_count
      pending_count = patient.active_srs2_hetero_reports.where(status: :pending).count
      completed_count = patient.active_srs2_hetero_reports.where(status: :completed).count
      
      if pending_count > 0
        badges << content_tag(:span, "#{pending_count} Heterorelato(s) Pendente(s)", class: "badge bg-warning")
      end
      if completed_count > 0
        badges << content_tag(:span, "#{completed_count} Heterorelato(s) Concluído(s)", class: "badge bg-success")
      end
    else
      badges << content_tag(:span, "Heterorelato Disponível", class: "badge bg-secondary")
    end

    safe_join(badges)
  end

  # Helper para verificar se uma escala pode ser solicitada para um paciente
  def can_request_scale_for?(patient, psychometric_scale)
    return false unless patient && psychometric_scale
    ScaleRequest.can_create_for?(patient, psychometric_scale)
  end

  # Helper para mostrar mensagem explicativa sobre limitações das escalas SRS-2
  def srs2_limitation_message_for(patient, psychometric_scale)
    return unless patient && psychometric_scale

    case psychometric_scale.code
    when "SRS2SR"
      unless patient.can_receive_srs2_self_report?
        content_tag(:div, class: "alert alert-info") do
          "Este paciente já possui um autorelato SRS-2 ativo. Cada paciente pode ter apenas um autorelato SRS-2 (pendente ou concluído)."
        end
      end
    when "SRS2HR"
      unless patient.can_receive_srs2_hetero_report?
        content_tag(:div, class: "alert alert-info") do
          "Este paciente já possui um heterorelato SRS-2 ativo. Cada paciente pode ter apenas um heterorelato SRS-2 (pendente ou concluído)."
        end
      end
    end
  end

  # Helper para obter o autorrelato SRS-2 correspondente (para links de interpretação)
  def find_corresponding_self_report_for(patient)
    return unless patient

    ScaleResponse.joins(:scale_request, :psychometric_scale)
                 .where(patient: patient)
                 .where(scale_requests: { status: :completed })
                 .where(psychometric_scales: { code: "SRS2SR" })
                 .first
  end

  # Helper para gerar link de interpretação apropriado baseado no tipo de escala
  def interpretation_link_for(scale_response)
    return unless scale_response

    case scale_response.psychometric_scale.code
    when "SRS2SR"
      # Para autorelato, usa a própria resposta
      interpretation_scale_response_path(scale_response)
    when "SRS2HR"
      # Para heterorelato, usa o autorrelato correspondente se existir
      self_report = find_corresponding_self_report_for(scale_response.patient)
      if self_report
        interpretation_scale_response_path(self_report)
      else
        nil # Não há autorrelato para comparar
      end
    else
      # Para outras escalas, usa a própria resposta
      interpretation_scale_response_path(scale_response)
    end
  end
end
