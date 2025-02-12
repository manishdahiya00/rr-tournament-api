class User < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :redeems, dependent: :destroy
end
