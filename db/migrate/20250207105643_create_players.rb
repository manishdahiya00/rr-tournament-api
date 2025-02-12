class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players, id: :uuid do |t|
      t.string :user_id
      t.string :name
      t.string :uid
      t.string :username
      t.string :match_id
      t.string :slot_no
      t.timestamps
    end
  end
end
