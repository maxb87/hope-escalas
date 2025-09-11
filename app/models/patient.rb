class Patient < ApplicationRecord
  acts_as_paranoid
  has_one :user, as: :account, dependent: :destroy
  has_many :scale_requests, dependent: :destroy
  has_many :scale_responses, dependent: :destroy

  validates :full_name, presence: true
  validates :email, presence: true
  validates :gender, presence: true, inclusion: { in: %w[male female] }

  def pending_scale_requests_count
    scale_requests.pending.count
  end

  def completed_scale_responses_count
    scale_responses.count
  end

  def age
    return nil if birthday.nil?
    
    today = Date.current
    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end
end
