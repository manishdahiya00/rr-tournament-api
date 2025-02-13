class AppBanner < ApplicationRecord
  scope :active, -> { where(published: true).order(created_at: :desc) }
end
