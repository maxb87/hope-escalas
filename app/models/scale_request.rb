class ScaleRequest < ApplicationRecord
  acts_as_paranoid

  belongs_to :patient
  belongs_to :professional
  belongs_to :psychometric_scale
  has_one :scale_response, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[pending completed expired cancelled] }
  validates :requested_at, presence: true
  validates :expires_at, presence: true, if: :pending?
  validate :expires_at_after_requested_at, if: :expires_at?

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :expired, -> { where(status: "expired") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :active, -> { where(status: [ "pending" ]) }
  scope :recent, -> { order(requested_at: :desc) }

  before_create :set_requested_at, unless: :requested_at?
  before_create :set_expires_at, unless: :expires_at?

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end

  def expired?
    status == "expired"
  end

  def cancelled?
    status == "cancelled"
  end

  def expired_by_time?
    expires_at.present? && expires_at < Time.current
  end

  def can_be_completed?
    pending? && !expired_by_time?
  end

  def complete!
    update!(status: "completed") if can_be_completed?
  end

  def cancel!
    update!(status: "cancelled") if pending?
  end

  def expire!
    update!(status: "expired") if pending?
  end

  private

  def set_requested_at
    self.requested_at = Time.current
  end

  def set_expires_at
    self.expires_at = 7.days.from_now
  end

  def expires_at_after_requested_at
    if expires_at <= requested_at
      errors.add(:expires_at, "deve ser posterior à data de solicitação")
    end
  end
end
