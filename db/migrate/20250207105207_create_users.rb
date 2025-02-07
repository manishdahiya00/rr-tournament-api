class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.string :security_token
      t.integer :wallet_balance
      t.boolean :is_banned, default: false
      t.string :source_ip

      t.timestamps
    end
  end
end
