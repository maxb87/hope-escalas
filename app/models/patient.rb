class Patient < ApplicationRecord
  acts_as_paranoid
  has_one :user, as: :account, dependent: :destroy

  validates :full_name, presence: true
  validates :email, presence: true
end
