ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'json'

# Prevent Sinatra from starting the server
set :run, false if defined?(Sinatra)

require_relative '../app.rb'

class ApiTransactionUpdateTest < Minitest::Test
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

  def test_update_transaction_category_api
    new_category = 'Updated Category'
    
    # Send PATCH request with JSON body
    patch "/api/transactions/#{@transaction.id}", 
          { category: new_category }.to_json, 
          { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 200, last_response.status
    
    response_body = JSON.parse(last_response.body)
    assert_equal new_category, response_body['category']
    
    # Verify database update
    updated_transaction = Transaction.find(@transaction.id)
    assert_equal new_category, updated_transaction.category
  end

  def test_update_transaction_not_found
    patch "/api/transactions/999999", 
          { category: 'New Cat' }.to_json, 
          { 'CONTENT_TYPE' => 'application/json' }
    
    assert_equal 404, last_response.status
  end
end
