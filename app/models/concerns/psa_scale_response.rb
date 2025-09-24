# frozen_string_literal: true

module PsaScaleResponse
  extend ActiveSupport::Concern

  # Check if this is a PSA scale
  def psa_scale?
    psychometric_scale.code == "PSA"
  end

  # PSA score and interpretation
  def psa_score
    return nil unless psa_scale?
    total_score
  end

  def psa_interpretation
    return nil unless psa_scale?
    interpretation
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

  # Método para calcular score usando o serviço PSA
  def calculate_psa_score_with_service
    # Calcular idade do paciente
    patient_age = calculate_patient_age

    results_hash = Scoring::Psa.calculate(
      answers,
      scale_version: psychometric_scale.version,
      patient_gender: patient.gender,
      patient_age: patient_age,
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