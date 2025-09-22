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
end
