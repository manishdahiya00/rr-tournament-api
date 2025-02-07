class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches, id: :uuid do |t|
      t.string :category_id
      t.string :title
      t.string :subtitle
      t.string :timing
      t.integer :winning_prize
      t.integer :per_kill
      t.integer :entry_fee
      t.boolean :published
      t.string :status
      t.string :image_url
      t.integer :total_slots
      t.integer :slots_left
      t.text :rules

      t.timestamps
    end
  end
end
