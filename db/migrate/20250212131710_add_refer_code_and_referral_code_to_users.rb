class AddReferCodeAndReferralCodeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :refer_code, :string, default: ""
    add_column :users, :referral_code, :string, default: ""
  end
end
