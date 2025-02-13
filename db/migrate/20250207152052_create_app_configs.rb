class CreateAppConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :app_configs do |t|
      t.string :tel1
      t.string :tel2
      t.integer :signup_bonus
      t.integer :refer_bonus
      t.string :version
      t.string :update_url

      t.timestamps
    end
  end
end
