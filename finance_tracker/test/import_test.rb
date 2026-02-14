require_relative 'test_helper'
require 'csv'
require 'tempfile'

class ImportTest < Minitest::Test
  include TestHelpers

  def setup
    Transaction.destroy_all
  end

  def test_import_valid_csv
    # Create a temporary CSV file with sample data
    # Format: Date, Amount, Description, Balance
    csv_content = <<~CSV
      13/02/2026,"-75.00","Woolworths Bondi Junction","+24.41"
      14/02/2026,"+5000.00","Salary Payment","+5024.41"
      15/02/2026,"-20.00","Uber Trip","+5004.41"
    CSV
    
    file = Tempfile.new(['test_import', '.csv'])
    file.write(csv_content)
    file.rewind

    post '/import', file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
    
    assert last_response.redirect?
    follow_redirect!
    assert last_response.ok?
    assert_includes last_request.url, 'imported=3'
    
    assert_equal 3, Transaction.count
    
    # Check Expense with Auto-categorization
    expense = Transaction.find_by(description: 'Woolworths Bondi Junction')
    assert_equal 75.0, expense.amount.to_f
    assert_equal 'expense', expense.transaction_type
    assert_equal 'Groceries', expense.category 
    
    # Check Income with Auto-categorization
    income = Transaction.find_by(description: 'Salary Payment')
    assert_equal 5000.0, income.amount.to_f
    assert_equal 'income', income.transaction_type
    assert_equal 'Salary', income.category

    # Check another expense
    uber = Transaction.find_by(description: 'Uber Trip')
    assert_equal 20.0, uber.amount.to_f
    assert_equal 'Transportation', uber.category

    file.close
    file.unlink
  end

  def test_import_prevents_duplicates
    csv_content = <<~CSV
      13/02/2026,"-75.00","Unique Transaction","+24.41"
    CSV
    
    file = Tempfile.new(['test_import', '.csv'])
    file.write(csv_content)
    file.rewind

    # First Import
    post '/import', file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
    assert_equal 1, Transaction.count
    
    # Second Import (same file)
    file.rewind
    post '/import', file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
    
    # Should not create new transactions
    assert_equal 1, Transaction.count
    
    file.close
    file.unlink
  end

  def test_import_no_file
    post '/import'
    assert last_response.redirect?
    follow_redirect!
    assert last_response.ok?
    # Should not have 'imported=' query param or it should be 0 if logic handles it differently? 
    # Looking at app.rb: if params[:file]... else redirect '/'
    refute_includes last_request.url, 'imported='
  end
end
