require_relative 'app'
require 'date'

# Create database and table if they don't exist
ActiveRecord::Base.connection.create_table :transactions, force: true do |t|
  t.string :description, null: false
  t.decimal :amount, precision: 10, scale: 2, null: false
  t.string :transaction_type, null: false
  t.string :category
  t.date :transaction_date, null: false
  t.timestamps
end

ActiveRecord::Base.connection.add_index :transactions, :transaction_date
ActiveRecord::Base.connection.add_index :transactions, :transaction_type

puts "✓ Created transactions table"

# Seed data
Transaction.destroy_all

categories = {
  income: ['Salary', 'Freelance', 'Investment', 'Bonus', 'Gift'],
  expense: ['Groceries', 'Rent', 'Utilities', 'Entertainment', 'Transportation', 'Healthcare', 'Shopping', 'Dining']
}

# Generate transactions for each of the last 6 months
6.times do |month_offset|
  month_date = Date.today - (month_offset * 30)
  
  # Income transactions (2-4 per month)
  rand(2..4).times do
    Transaction.create!(
      description: "#{categories[:income].sample} - #{month_date.strftime('%B')}",
      amount: rand(1000..5000),
      transaction_type: 'income',
      category: categories[:income].sample,
      transaction_date: Date.new(month_date.year, month_date.month, 1) + rand(0..28)
    )
  end
  
  # Expense transactions (8-15 per month)
  rand(8..15).times do
    Transaction.create!(
      description: "#{categories[:expense].sample} - #{month_date.strftime('%B')}",
      amount: rand(20..800),
      transaction_type: 'expense',
      category: categories[:expense].sample,
      transaction_date: Date.new(month_date.year, month_date.month, 1) + rand(0..28)
    )
  end
end

puts "✓ Created #{Transaction.count} transactions"
puts "  Total Income: $#{Transaction.total_income.round(2)}"
puts "  Total Expenses: $#{Transaction.total_expenses.round(2)}"
puts "  Balance: $#{Transaction.balance.round(2)}"
puts "\n✓ Database setup complete!"
