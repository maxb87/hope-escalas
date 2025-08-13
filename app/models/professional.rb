class Professional < ApplicationRecord
  acts_as_paranoid
  has_one :user, as: :account, dependent: :destroy
  has_many :scale_requests, dependent: :destroy

  validates :full_name, presence: true
  validates :email, presence: true

  def pending_scale_requests_count
    scale_requests.pending.count
  end

  def completed_scale_requests_count
    scale_requests.completed.count
  end
end
