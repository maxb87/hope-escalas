class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Um usuário pertence a uma conta (Professional ou Patient)
  belongs_to :account, polymorphic: true, optional: true
end
