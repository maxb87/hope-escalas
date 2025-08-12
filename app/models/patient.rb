class Patient < ApplicationRecord
  acts_as_paranoid
  has_one :user, as: :account, dependent: :destroy
  accepts_nested_attributes_for :user

  after_create :create_associated_user!

  validates :full_name, presence: true
  validates :email, presence: true

  private

  def create_associated_user!
    return if user.present?

    generated_password = SecureRandom.base58(16)
    user_attributes = {
      email: email,
      password: generated_password,
      password_confirmation: generated_password
    }
    user_attributes[:force_password_reset] = true if User.column_names.include?("force_password_reset")

    build_user(user_attributes)
    user.save!
  end
end
