class CreateAppBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :app_banners do |t|
      t.string :image_url
      t.string :action_url
      t.boolean :published, default: true

      t.timestamps
    end
  end
end
