ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'active_record'
require_relative '../app'

# Configure in-memory database for testing
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Define schema for the test database
ActiveRecord::Schema.define do
  create_table :transactions, force: true do |t|
    t.string :description, null: false
    t.decimal :amount, precision: 10, scale: 2, null: false
    t.string :transaction_type, null: false
    t.string :category
    t.date :transaction_date, null: false
    t.timestamps
  end
end

module TestHelpers
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end
