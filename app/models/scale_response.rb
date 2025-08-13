class ScaleResponse < ApplicationRecord
  acts_as_paranoid

  belongs_to :scale_request
  belongs_to :patient
  belongs_to :psychometric_scale

  validates :answers, presence: true
  validates :total_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :interpretation, presence: true
  validates :completed_at, presence: true
  validate :answers_structure_valid
  validate :all_required_items_answered

  before_validation :calculate_score, if: :answers_changed?
  before_validation :set_completed_at, unless: :completed_at?

  scope :recent, -> { order(completed_at: :desc) }
  scope :by_scale, ->(scale) { where(psychometric_scale: scale) }

  def bdi_score
    return nil unless psychometric_scale.code == "BDI"
    total_score
  end

  def bdi_interpretation
    return nil unless psychometric_scale.code == "BDI"
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

  private

  def calculate_score
    return unless answers.present? && psychometric_scale.present?

    case psychometric_scale.code
    when "BDI"
      calculate_bdi_score
    when "BAI"
      calculate_bai_score
    else
      calculate_generic_score
    end
  end

  def calculate_bdi_score
    self.total_score = answers.values.sum(&:to_i)
    self.interpretation = interpret_bdi_score(total_score)
  end

  def calculate_bai_score
    self.total_score = answers.values.sum(&:to_i)
    self.interpretation = interpret_bai_score(total_score)
  end

  def calculate_generic_score
    self.total_score = answers.values.sum(&:to_i)
    self.interpretation = "Pontuação total: #{total_score}"
  end

  def interpret_bdi_score(score)
    case score
    when 0..11 then "Mínima"
    when 12..19 then "Leve"
    when 20..27 then "Moderada"
    when 28..63 then "Grave"
    else "Pontuação inválida"
    end
  end

  def interpret_bai_score(score)
    case score
    when 0..7 then "Mínima"
    when 8..15 then "Leve"
    when 16..25 then "Moderada"
    when 26..63 then "Grave"
    else "Pontuação inválida"
    end
  end

  def set_completed_at
    self.completed_at = Time.current
  end

  def answers_structure_valid
    return unless answers.present?

    answers.each do |item_key, value|
      unless item_key.match?(/\Aitem_\d+\z/)
        errors.add(:answers, "estrutura inválida: #{item_key}")
        return
      end

      unless value.to_s.match?(/\A[0-3]\z/)
        errors.add(:answers, "valor inválido para #{item_key}: #{value}")
        return
      end
    end
  end

  def all_required_items_answered
    return unless psychometric_scale.present? && answers.present?

    required_items = psychometric_scale.scale_items.required
    answered_items = answers.keys.map { |k| k.gsub("item_", "").to_i }

    missing_items = required_items.pluck(:item_number) - answered_items

    if missing_items.any?
      errors.add(:answers, "itens obrigatórios não respondidos: #{missing_items.join(', ')}")
    end
  end
end
