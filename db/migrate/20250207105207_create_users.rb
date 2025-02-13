class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email
      t.string :otp
      t.string :security_token
      t.integer :wallet_balance
      t.boolean :is_banned, default: false
      t.string :source_ip
      t.string :version_name
      t.string :version_code
      t.string :refer_code
      t.string :referral_code
      t.timestamps
    end
  end
end
