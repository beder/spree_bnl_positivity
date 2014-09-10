class CreateBnlPositivityTransactions < ActiveRecord::Migration
  def change
    create_table :bnl_positivity_transactions do |t|
      t.string :payment_id
      t.string :transaction_id

      t.timestamps
    end
  end
end
