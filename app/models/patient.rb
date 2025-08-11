class Patient < ApplicationRecord
  acts_as_paranoid # soft delete capability

  # Rails-side validations complement DB constraints
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  validates :full_name, presence: true, length: { minimum: 7 }
  validates :birthday, presence: true
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }
  validates :cpf, presence: true, format: { with: /\A\d{11}\z/ }
end
