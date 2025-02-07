class Category < ApplicationRecord
  scope :published, -> { where(published: true).order(created_at: :desc) }

  has_many :matches, dependent: :destroy
end
