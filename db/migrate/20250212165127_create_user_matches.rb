class CreateUserMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :user_matches do |t|
      t.string :user_id
      t.string :match_id
      t.string :player_id

      t.timestamps
    end
  end
end
