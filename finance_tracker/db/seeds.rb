# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
Transaction.destroy_all

# Create sample transactions for the last 6 months
categories = {
  income: ['Salary', 'Freelance', 'Investment', 'Bonus', 'Gift'],
  expense: ['Groceries', 'Rent', 'Utilities', 'Entertainment', 'Transportation', 'Healthcare', 'Shopping', 'Dining']
}

# Generate transactions for each of the last 6 months
6.times do |month_offset|
  month_date = month_offset.months.ago
  
  # Income transactions (2-4 per month)
  rand(2..4).times do
    Transaction.create!(
      description: "#{categories[:income].sample} - #{month_date.strftime('%B')}",
      amount: rand(1000..5000),
      transaction_type: 'income',
      category: categories[:income].sample,
      transaction_date: month_date.beginning_of_month + rand(0..28).days
    )
  end
  
  # Expense transactions (8-15 per month)
  rand(8..15).times do
    Transaction.create!(
      description: "#{categories[:expense].sample} - #{month_date.strftime('%B')}",
      amount: rand(20..800),
      transaction_type: 'expense',
      category: categories[:expense].sample,
      transaction_date: month_date.beginning_of_month + rand(0..28).days
    )
  end
end

puts "Created #{Transaction.count} transactions"
puts "Total Income: $#{Transaction.total_income}"
puts "Total Expenses: $#{Transaction.total_expenses}"
puts "Balance: $#{Transaction.balance}"
