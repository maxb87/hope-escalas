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
  before_destroy :cancel_associated_scale_request

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

  def total_score
    results.dig("metrics", "raw_score") || 0
  end

  # Check if this is a hetero-report scale
  def hetero_report?
    psychometric_scale.code == "SRS2HR"
  end

  # Check if this is any SRS-2 scale
  def srs2_scale?
    [ "SRS2SR", "SRS2HR" ].include?(psychometric_scale.code)
  end


  # Métodos para obter respostas formatadas para exibição
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

  # Retorna uma lista dos domínios das subescalas com seus níveis para uso na view
  def subscale_domains_with_levels
    return [] unless results.present? && results["subscales"].present?

    subscales = results["subscales"]

    # Ordem específica dos domínios conforme solicitado
    domain_order = [
      "social_awareness",      # Percepção Social
      "social_cognition",      # Cognição Social
      "social_communication",  # Comunicação Social
      "social_motivation",     # Motivação Social
      "restricted_interests",  # Padrões Restritos ou Repetitivos
      "social_interaction"     # Interação Social Global
    ]

    # Criar array com informações dos domínios na ordem específica
    ordered_domains = []
    normal_domains = []

    domain_order.each do |domain_key|
      next unless subscales[domain_key]

      domain_data = subscales[domain_key]
      domain_info = {
        key: domain_key,
        title: domain_data["title"],
        level: domain_data["level"],
        t_score: domain_data["t_score"],
        raw_score: domain_data["raw_score"],
        percentile: domain_data["percentile"],
        description: domain_data["description"],
        interpretation: domain_data["interpretation"],
        items: domain_data["items"]
      }

      # Separar domínios normais dos problemáticos
      if domain_data["level"] == "normal"
        normal_domains << domain_info
      else
        ordered_domains << domain_info
      end
    end

    # NÃO ordenar por severidade - manter a ordem específica dos domínios
    # Adicionar domínios normais no final
    ordered_domains + normal_domains
  end

  # Retorna apenas os domínios com problemas (não normais) na ordem específica
  def leve_domains
    # Manter a ordem específica dos domínios, apenas filtrando os leves
    subscale_domains_with_levels.select { |domain| domain[:level] == "leve" }
  end

  def moderado_domains
    subscale_domains_with_levels.select { |domain| domain[:level] == "moderado" }
  end

  def severo_domains
    subscale_domains_with_levels.select { |domain| domain[:level] == "severo" }
  end

  # Retorna apenas os domínios normais
  def normal_domains
    subscale_domains_with_levels.select { |domain| domain[:level] == "normal" }
  end

  # Retorna o domínio com maior severidade (primeiro da lista de problemáticos)
  def worst_domain
    if severo_domains.any?
      severo_domains.max_by { |domain| domain[:t_score] }
    elsif moderado_domains.any?
      moderado_domains.max_by { |domain| domain[:t_score] }
    elsif leve_domains.any?
      leve_domains.max_by { |domain | domain[:t_score] }
    else
      normal_domains.max_by { |domain | domain[:t_score] }
    end
  end

  def lowest_domain
    if leve_domains.any?
      leve_domains.min_by { |domain| domain[:t_score] }
    elsif moderado_domains.any?
      moderado_domains.min_by { |domain| domain[:t_score] }
    elsif severo_domains.any?
      severo_domains.min_by { |domain| domain[:t_score] }
    else
      normal_domains.min_by { |domain | domain[:t_score] }
    end
  end

  # Retorna o domínio com a segunda maior pontuação
  def second_highest_domain
    all_domains = subscale_domains_with_levels
    return nil if all_domains.size < 2

    # Ordenar por t_score em ordem decrescente e pegar o segundo
    sorted_domains = all_domains.sort_by { |domain| -domain[:t_score] }
    sorted_domains[1]
  end

  # Segundo maior dentro de cada categoria de severidade
  def second_worst_domain
    if severo_domains.size >= 2
      severo_domains.sort_by { |domain| -domain[:t_score] }[1]
    elsif severo_domains.size == 1 && moderado_domains.any?
      moderado_domains.max_by { |domain| domain[:t_score] }
    elsif severo_domains.empty? && moderado_domains.size >= 2
      moderado_domains.sort_by { |domain| -domain[:t_score] }[1]
    elsif moderado_domains.size == 1 && leve_domains.any?
      leve_domains.max_by { |domain| domain[:t_score] }
    elsif moderado_domains.empty? && leve_domains.size >= 2
      leve_domains.sort_by { |domain| -domain[:t_score] }[1]
    elsif leve_domains.size == 1 && normal_domains.any?
      normal_domains.max_by { |domain| domain[:t_score] }
    elsif leve_domains.empty? && normal_domains.size >= 2
      normal_domains.sort_by { |domain| -domain[:t_score] }[1]
    else
      nil
    end
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
        scale_type: scale_type,
        patient: patient  # Passar o objeto paciente
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
