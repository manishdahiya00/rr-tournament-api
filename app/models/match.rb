class Match < ApplicationRecord
  scope :upcoming, -> { where(published: true, status: "upcoming").order("created_at ASC") }
  scope :live, -> { where(published: true, status: "live").order("created_at ASC") }
  scope :completed, -> { where(published: true, status: "completed").order("created_at ASC") }

  belongs_to :category
  has_many :players, dependent: :destroy
end
