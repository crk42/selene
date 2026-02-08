require_relative '../test_helper'

class TransactionTest < Minitest::Test
  def setup
    Transaction.destroy_all
  end

  def test_valid_transaction
    transaction = Transaction.new(
      description: 'Salary',
      amount: 5000,
      transaction_type: 'income',
      transaction_date: Date.today,
      category: 'Work'
    )
    assert transaction.valid?
  end

  def test_invalid_without_description
    transaction = Transaction.new(amount: 100, transaction_type: 'expense', transaction_date: Date.today)
    refute transaction.valid?
    assert_includes transaction.errors[:description], "can't be blank"
  end

  def test_invalid_negative_amount
    transaction = Transaction.new(amount: -100, description: 'Test', transaction_type: 'expense', transaction_date: Date.today)
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

  def test_monthly_summary
    Transaction.create!(description: 'Income', amount: 1000, transaction_type: 'income', transaction_date: Date.today)
    
    summary = Transaction.monthly_summary(6)
    assert_equal 6, summary.length
    assert_equal Date.today.strftime('%B %Y'), summary.last[:month]
    assert_equal 1000.0, summary.last[:income]
  end

  def test_category_expenses
    Transaction.create!(description: 'Rent', amount: 1500, transaction_type: 'expense', transaction_date: Date.today, category: 'Housing')
    Transaction.create!(description: 'Groceries', amount: 300, transaction_type: 'expense', transaction_date: Date.today, category: 'Food')
    Transaction.create!(description: 'Lunch', amount: 20, transaction_type: 'expense', transaction_date: Date.today, category: 'Food')
    Transaction.create!(description: 'Salary', amount: 5000, transaction_type: 'income', transaction_date: Date.today, category: 'Work')

    categories = Transaction.category_expenses
    assert_equal 2, categories.keys.length
    assert_equal 1500, categories['Housing']
    assert_equal 320, categories['Food']
    assert_nil categories['Work'] # Should only include expenses
  end
end
