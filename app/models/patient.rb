class Patient < ApplicationRecord
  acts_as_paranoid
  has_one :user, as: :account, dependent: :destroy
  has_many :scale_requests, dependent: :destroy
  has_many :scale_responses, dependent: :destroy

  validates :full_name, presence: true
  validates :email, presence: true

  def pending_scale_requests_count
    scale_requests.pending.count
  end

  def completed_scale_responses_count
    scale_responses.count
  end
end
