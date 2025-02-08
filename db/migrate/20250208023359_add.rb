class Add < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :room_id, :string
    add_column :matches, :room_pass, :string
  end
end
