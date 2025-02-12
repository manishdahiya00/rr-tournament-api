class CreateRedeems < ActiveRecord::Migration[8.0]
  def change
    create_table :redeems do |t|
      t.string :mobile_number
      t.string :upi_id
      t.integer :amount
      t.string :user_id
      t.boolean :paid

      t.timestamps
    end
  end
end
