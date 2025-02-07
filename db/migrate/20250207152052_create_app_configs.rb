class CreateAppConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :app_configs do |t|
      t.string :phn1
      t.string :phn2
      t.string :tel1
      t.string :tel2
      t.string :banner_image
      t.integer :signup_bonus

      t.timestamps
    end
  end
end
