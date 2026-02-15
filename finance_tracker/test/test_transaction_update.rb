ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

# Prevent Sinatra from starting the server
set :run, false if defined?(Sinatra)

require_relative '../app.rb'

class TransactionUpdateTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    Transaction.destroy_all
    @transaction = Transaction.create(
      description: 'Test Transaction',
      amount: 100.0,
      transaction_type: 'expense',
      category: 'Test Category',
      transaction_date: Date.today
    )
  end

  def test_update_transaction
    post "/transactions/#{@transaction.id}", {
      description: 'Updated Transaction',
      amount: 200.0,
      transaction_type: 'income',
      category: 'Updated Category',
      transaction_date: Date.today.to_s
    }

    assert_equal 302, last_response.status
    
    updated_transaction = Transaction.find(@transaction.id)
    assert_equal 'Updated Transaction', updated_transaction.description
    assert_equal 200.0, updated_transaction.amount
    assert_equal 'income', updated_transaction.transaction_type
    assert_equal 'Updated Category', updated_transaction.category
  end
end
