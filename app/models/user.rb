class User < ApplicationRecord
  has_secure_password

  has_many :players, dependent: :destroy
  has_many :redeems, dependent: :destroy
end
