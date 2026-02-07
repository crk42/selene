class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :transaction_type, null: false
      t.string :category
      t.date :transaction_date, null: false

      t.timestamps
    end

    add_index :transactions, :transaction_date
    add_index :transactions, :transaction_type
  end
end
