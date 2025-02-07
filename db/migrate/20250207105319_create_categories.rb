class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :title
      t.string :image_url
      t.boolean :published

      t.timestamps
    end
  end
end
