# frozen_string_literal: true

module PsaScaleResponse
  extend ActiveSupport::Concern

  # Check if this is PSA scale
  def psa_scale?
    psychometric_scale.code == "PSA"
  end


  # Validação específica para PSA (escala 1-5)
  def validate_psa_answers
    return unless psa_scale?

    answers.each do |item_key, value|
      unless item_key.match?(/\Aitem_\d+\z/)
        errors.add(:answers, I18n.t("scale_responses.errors.invalid_key", key: item_key))
        break
      end
      # PSA uses 1-5 scale
      unless value.to_s.match?(/\A[1-5]\z/)
        errors.add(:answers, I18n.t("scale_responses.errors.invalid_value_psa", key: item_key, value: value))
        break
      end
    end
  end
end
