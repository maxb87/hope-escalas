class PsychometricScale < ApplicationRecord
  acts_as_paranoid

  has_many :scale_items, class_name: "PsychometricScaleItem", dependent: :destroy
  has_many :scale_requests, dependent: :destroy
  has_many :scale_responses, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z]+\z/, message: "deve conter apenas letras maiúsculas" }
  validates :is_active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:name) }

  def to_s
    "#{code} - #{name}"
  end
end
