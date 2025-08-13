class PsychometricScaleItem < ApplicationRecord
  belongs_to :psychometric_scale

  validates :item_number, presence: true, uniqueness: { scope: :psychometric_scale_id }
  validates :question_text, presence: true
  validates :options, presence: true
  validates :is_required, inclusion: { in: [ true, false ] }

  scope :ordered, -> { order(:item_number) }
  scope :required, -> { where(is_required: true) }

  def to_s
    "Item #{item_number}: #{question_text}"
  end

  def option_texts
    options.values
  end

  def option_scores
    options.keys.map(&:to_i)
  end
end
