require_relative 'test_helper'

class AppTest < Minitest::Test
  include TestHelpers

  def setup
    Transaction.destroy_all
  end

  def test_dashboard_loads
    get '/'
    assert last_response.ok?
    assert_includes last_response.body, 'Finance Tracker'
  end

  def test_transactions_history_loads
    get '/transactions'
    assert last_response.ok?
    assert_includes last_response.body, 'Transaction History'
  end

  def test_create_transaction
    post '/transactions', {
      description: 'Test Transaction',
      amount: '123.45',
      transaction_type: 'expense',
      category: 'Test',
      transaction_date: Date.today.to_s
    }
    
    assert last_response.redirect?
    follow_redirect!
    assert last_response.ok?
    
    transaction = Transaction.last
    assert_equal 'Test Transaction', transaction.description
    assert_equal 123.45, transaction.amount.to_f
  end

  def test_delete_transaction
    transaction = Transaction.create!(
      description: 'To Delete',
      amount: 50,
      transaction_type: 'expense',
      transaction_date: Date.today
    )
    
    post "/transactions/#{transaction.id}/delete"
    
    assert last_response.redirect?
    assert_nil Transaction.find_by(id: transaction.id)
  end

  def test_bulk_delete_transactions
    t1 = Transaction.create!(description: 'T1', amount: 10, transaction_type: 'expense', transaction_date: Date.today)
    t2 = Transaction.create!(description: 'T2', amount: 20, transaction_type: 'expense', transaction_date: Date.today)
    t3 = Transaction.create!(description: 'T3', amount: 30, transaction_type: 'expense', transaction_date: Date.today)
    
    post '/transactions/bulk-delete', { ids: [t1.id, t2.id] }
    
    assert last_response.redirect?
    assert_nil Transaction.find_by(id: t1.id)
    assert_nil Transaction.find_by(id: t2.id)
    refute_nil Transaction.find_by(id: t3.id)
  end

  def test_dashboard_contains_category_data
    Transaction.create!(description: 'Rent', amount: 1500, transaction_type: 'expense', transaction_date: Date.today, category: 'Housing')
    
    get '/'
    assert last_response.ok?
    # Check if the chart labels exist in the response (as JSON data for Chart.js)
    assert_includes last_response.body, 'Housing'
  end
end
