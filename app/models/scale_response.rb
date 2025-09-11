class ScaleResponse < ApplicationRecord
  acts_as_paranoid

  belongs_to :scale_request
  belongs_to :patient
  belongs_to :psychometric_scale

  # Validações: quando não há respostas, permitimos campos calculados em branco
  validates :total_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :interpretation, presence: true, if: -> { answers.present? }
  validates :completed_at, presence: true, if: -> { answers.present? }
  validate :validate_answers
  validate :validate_hetero_report_fields

  before_validation :calculate_score, if: :answers_changed?
  before_validation :set_completed_at, if: -> { answers.present? && !completed_at? }

  scope :recent, -> { order(completed_at: :desc) }
  scope :by_scale, ->(scale) { where(psychometric_scale: scale) }

  def srs2_score
    return nil unless srs2_scale?
    total_score
  end

  def srs2_interpretation
    return nil unless srs2_scale?
    interpretation
  end

  def answered_items_count
    answers.keys.count
  end

  def total_items_count
    psychometric_scale.scale_items.count
  end

  def completion_percentage
    return 0 if total_items_count.zero?
    (answered_items_count.to_f / total_items_count * 100).round(1)
  end

  def complete?
    completion_percentage == 100
  end

  # Método para acessar a interpretação dos resultados
  def interpretation_level
    results.dig("interpretation", "level") || "Não disponível"
  end

  # Check if this is a hetero-report scale
  def hetero_report?
    psychometric_scale.code == "SRS2HR"
  end

  # Check if this is any SRS-2 scale
  def srs2_scale?
    [ "SRS2SR", "SRS2HR" ].include?(psychometric_scale.code)
  end

  private

  def calculate_score
    return unless answers.present? && psychometric_scale.present?

    case psychometric_scale.code
    when "SRS2SR", "SRS2HR"
      # Calcular idade do paciente
      patient_age = calculate_patient_age
      # Determinar tipo de escala baseado no código
      scale_type = psychometric_scale.code == "SRS2SR" ? "self_report" : "parent_report"

      results_hash = Scoring::Srs2.calculate(
        answers,
        scale_version: psychometric_scale.version,
        patient_gender: patient.gender,
        patient_age: patient_age,
        scale_type: scale_type
      )
      apply_results!(results_hash)
    else
      calculate_generic_score
    end
  end

  def calculate_srs2_score
    self.total_score = answers.values.sum(&:to_i)
    self.interpretation = interpret_srs2_score(total_score)
  end

  def calculate_generic_score
    self.total_score = answers.values.sum(&:to_i)
    self.interpretation = "Pontuação total: #{total_score}"
    # Preenche estrutura de results mínima para manter contrato
    self.results = {
      "schema_version" => 1,
      "scale_code" => psychometric_scale.code,
      "scale_version" => psychometric_scale.version,
      "computed_at" => Time.current.iso8601,
      "metrics" => { "total" => total_score },
      "subscales" => {},
      "interpretation" => { "level" => interpretation }
    }
    self.results_schema_version = 1
    self.computed_at = Time.current
  end

  def interpret_srs2_score(score)
    case score
    when 65..90 then "Normal"
    when 91..120 then "Leve"
    when 121..150 then "Moderado"
    when 151..260 then "Severo"
    else "Pontuação inválida"
    end
  end

  def set_completed_at
    self.completed_at = Time.current
  end

  def apply_results!(hash)
    self.results = hash
    self.results_schema_version = hash["schema_version"] || 1
    self.computed_at = Time.zone.parse(hash["computed_at"]) rescue Time.current
    # Preencher campos legados
    if (total = hash.dig("metrics", "total"))
      self.total_score = total.to_i
    end
    if (level = hash.dig("interpretation", "level"))
      self.interpretation = level
    end
  end

  def validate_answers
    # Ordem de mensagens: 1) ausência, 2) itens faltantes, 3) estrutura/valores inválidos
    if answers.blank?
      errors.add(:answers, I18n.t("scale_responses.errors.answers_blank"))
      return
    end

    # Itens obrigatórios não respondidos
    if psychometric_scale.present?
      required_numbers = psychometric_scale.scale_items.required.pluck(:item_number)
      answered_numbers = answers.keys.map { |k| k.gsub("item_", "").to_i }
      missing = (required_numbers - answered_numbers).sort
      if missing.any?
        errors.add(:answers, I18n.t("scale_responses.errors.missing_required_items", items: missing.join(", ")))
      end
    end

    # Estrutura e domínio dos valores
    answers.each do |item_key, value|
      unless item_key.match?(/\Aitem_\d+\z/)
        errors.add(:answers, I18n.t("scale_responses.errors.invalid_key", key: item_key))
        break
      end
      # SRS-2 uses 1-4 scale instead of 0-3
      unless value.to_s.match?(/\A[1-4]\z/)
        errors.add(:answers, I18n.t("scale_responses.errors.invalid_value", key: item_key, value: value))
        break
      end
    end
  end

  def validate_hetero_report_fields
    if hetero_report?
      errors.add(:relator_name, "é obrigatório para formulários de heterorrelato") if relator_name.blank?
      errors.add(:relator_relationship, "é obrigatório para formulários de heterorrelato") if relator_relationship.blank?
    end
  end

  def calculate_patient_age
    return nil unless patient&.birthday

    today = Date.current
    birthday = patient.birthday

    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end
end
