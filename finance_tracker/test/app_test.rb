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
end
