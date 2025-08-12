class Patient < ApplicationRecord
  acts_as_paranoid # soft delete capability
  has_one :user, as: :account, dependent: :destroy
end
