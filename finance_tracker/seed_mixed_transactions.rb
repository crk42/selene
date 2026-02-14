require './app'

# Create a mixed category scenario
# Expense
Transaction.create!(
  transaction_date: Date.today,
  amount: 100.00,
  description: "Test Expense Groceries",
  transaction_type: 'expense',
  category: 'Groceries'
)

# Income in same category (e.g. refund)
Transaction.create!(
  transaction_date: Date.today,
  amount: 50.00,
  description: "Test Income Refund Groceries",
  transaction_type: 'income',
  category: 'Groceries'
)

puts "Seeded mixed transactions for Groceries."
