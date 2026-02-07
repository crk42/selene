require 'minitest/autorun'
require 'active_record'
require 'date'

# Configure in-memory database for testing
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

# Define schema
ActiveRecord::Schema.define do
  create_table :transactions do |t|
    t.string :description, null: false
    t.decimal :amount, precision: 10, scale: 2, null: false
    t.string :transaction_type, null: false
    t.string :category
    t.date :transaction_date, null: false
    t.timestamps
  end
end

# Load model
class Transaction < ActiveRecord::Base
  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense] }
  validates :transaction_date, presence: true

  scope :income, -> { where(transaction_type: 'income') }
  scope :expense, -> { where(transaction_type: 'expense') }
  scope :recent, -> { order(transaction_date: :desc) }

  def self.total_income(start_date = nil, end_date = nil)
    scope = income
    scope = scope.where(transaction_date: start_date..end_date) if start_date && end_date
    scope.sum(:amount)
  end

  def self.total_expenses(start_date = nil, end_date = nil)
    scope = expense
    scope = scope.where(transaction_date: start_date..end_date) if start_date && end_date
    scope.sum(:amount)
  end

  def self.balance(start_date = nil, end_date = nil)
    total_income(start_date, end_date) - total_expenses(start_date, end_date)
  end
end

class TransactionTest < Minitest::Test
  def setup
    Transaction.destroy_all
  end

  def test_valid_transaction
    transaction = Transaction.new(
      description: 'Salary',
      amount: 5000,
      transaction_type: 'income',
      transaction_date: Date.today
    )
    assert transaction.valid?
  end

  def test_invalid_without_description
    transaction = Transaction.new(amount: 100, transaction_type: 'expense')
    refute transaction.valid?
    assert_includes transaction.errors[:description], "can't be blank"
  end

  def test_invalid_negative_amount
    transaction = Transaction.new(amount: -100, description: 'Test', transaction_type: 'expense')
    refute transaction.valid?
    assert_includes transaction.errors[:amount], "must be greater than 0"
  end

  def test_invalid_transaction_type
    transaction = Transaction.new(
      description: 'Test',
      amount: 100,
      transaction_type: 'invalid_type',
      transaction_date: Date.today
    )
    refute transaction.valid?
    assert_includes transaction.errors[:transaction_type], "is not included in the list"
  end

  def test_total_income_calculation
    Transaction.create!(description: 'Salary', amount: 5000, transaction_type: 'income', transaction_date: Date.today)
    Transaction.create!(description: 'Bonus', amount: 1000, transaction_type: 'income', transaction_date: Date.today)
    Transaction.create!(description: 'Rent', amount: 2000, transaction_type: 'expense', transaction_date: Date.today)

    assert_equal 6000, Transaction.total_income
  end

  def test_total_expenses_calculation
    Transaction.create!(description: 'Rent', amount: 2000, transaction_type: 'expense', transaction_date: Date.today)
    Transaction.create!(description: 'Groceries', amount: 300, transaction_type: 'expense', transaction_date: Date.today)
    Transaction.create!(description: 'Salary', amount: 5000, transaction_type: 'income', transaction_date: Date.today)

    assert_equal 2300, Transaction.total_expenses
  end

  def test_balance_calculation
    Transaction.create!(description: 'Salary', amount: 5000, transaction_type: 'income', transaction_date: Date.today)
    Transaction.create!(description: 'Rent', amount: 1500, transaction_type: 'expense', transaction_date: Date.today)

    assert_equal 3500, Transaction.balance
  end

  def test_date_range_filtering
    # Transaction last month
    Transaction.create!(
      description: 'Old Income', 
      amount: 1000, 
      transaction_type: 'income', 
      transaction_date: Date.today - 35
    )
    
    # Transaction this month
    Transaction.create!(
      description: 'New Income', 
      amount: 2000, 
      transaction_type: 'income', 
      transaction_date: Date.today
    )

    this_month_start = Date.new(Date.today.year, Date.today.month, 1)
    this_month_end = Date.new(Date.today.year, Date.today.month, -1)

    assert_equal 2000, Transaction.total_income(this_month_start, this_month_end)
  end
end
