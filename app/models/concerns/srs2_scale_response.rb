# frozen_string_literal: true

module Srs2ScaleResponse
  extend ActiveSupport::Concern

  # Check if this is any SRS-2 scale
  def srs2_scale?
    ["SRS2SR", "SRS2HR"].include?(psychometric_scale.code)
  end

  # Check if this is a hetero-report scale
  def hetero_report?
    psychometric_scale.code == "SRS2HR"
  end

  # SRS-2 score and interpretation
  def srs2_score
    return nil unless srs2_scale?
    total_score
  end

  def srs2_interpretation
    return nil unless srs2_scale?
    interpretation
  end

  # Método para acessar a interpretação dos resultados
  def interpretation_level
    results.dig("interpretation", "level") || "Não disponível"
  end

  # Validação específica para SRS-2 (escala 1-4)
  def validate_srs2_answers
    return unless srs2_scale?

    answers.each do |item_key, value|
      unless item_key.match?(/\Aitem_\d+\z/)
        errors.add(:answers, I18n.t("scale_responses.errors.invalid_key", key: item_key))
        break
      end
      # SRS-2 uses 1-4 scale
      unless value.to_s.match?(/\A[1-4]\z/)
        errors.add(:answers, I18n.t("scale_responses.errors.invalid_value_srs2", key: item_key, value: value))
        break
      end
    end
  end

  # Validação específica para campos de heterorrelato
  def validate_srs2_hetero_report_fields
    if hetero_report?
      errors.add(:relator_name, "é obrigatório para formulários de heterorrelato") if relator_name.blank?
      errors.add(:relator_relationship, "é obrigatório para formulários de heterorrelato") if relator_relationship.blank?
    end
  end

  # Métodos para obter respostas formatadas para exibição (específico da SRS-2)
  def formatted_answers
    return [] unless answers.present? && psychometric_scale.present?

    psychometric_scale.scale_items.ordered.map do |item|
      answer_key = "item_#{item.item_number}"
      answer_value = answers[answer_key]

      if answer_value.present?
        {
          item_number: item.item_number,
          question_text: item.question_text,
          answer_value: answer_value,
          answer_text: item.options[answer_value.to_s] || "Resposta inválida",
          item: item
        }
      else
        {
          item_number: item.item_number,
          question_text: item.question_text,
          answer_value: nil,
          answer_text: "Não respondido",
          item: item
        }
      end
    end
  end

  # Obtém apenas as respostas que foram preenchidas
  def answered_items
    formatted_answers.select { |item| item[:answer_value].present? }
  end

  # Obtém respostas não preenchidas
  def unanswered_items
    formatted_answers.select { |item| item[:answer_value].blank? }
  end

  # Métodos de cálculo específicos da SRS-2
  def calculate_srs2_score
    self.total_score = answers.values.sum(&:to_i)
    # Para cálculo simples, usar interpretação genérica
    # O cálculo correto com T-score é feito em calculate_srs2_score_with_service
    self.interpretation = "Pontuação total: #{total_score}"
  end

  # Método para calcular score usando o serviço SRS-2
  def calculate_srs2_score_with_service
    # Calcular idade do paciente
    patient_age = calculate_patient_age
    # Determinar tipo de escala baseado no código
    scale_type = psychometric_scale.code == "SRS2SR" ? "self_report" : "parent_report"

    results_hash = Scoring::Srs2.calculate(
      answers,
      scale_version: psychometric_scale.version,
      patient_gender: patient.gender,
      patient_age: patient_age,
      scale_type: scale_type,
      patient: patient  # Passar o objeto paciente
    )
    apply_results!(results_hash)
  end

  private

  def calculate_patient_age
    return nil unless patient&.birthday

    today = Date.current
    birthday = patient.birthday

    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end
end
