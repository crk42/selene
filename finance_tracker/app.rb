require 'sinatra'
require 'sinatra/json'
require 'active_record'
require 'json'
require 'date'

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/finance_tracker.db'
)

# Transaction model
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

  def self.monthly_summary(months = 6)
    results = []
    months.times do |i|
      date = Date.today - (i * 30)
      month_start = Date.new(date.year, date.month, 1)
      month_end = Date.new(date.year, date.month, -1)
      
      results << {
        month: date.strftime('%B %Y'),
        income: total_income(month_start, month_end).to_f,
        expenses: total_expenses(month_start, month_end).to_f,
        balance: balance(month_start, month_end).to_f
      }
    end
    results.reverse
  end
end

# Routes
get '/' do
  @total_income = Transaction.total_income
  @total_expenses = Transaction.total_expenses
  @current_balance = Transaction.balance
  
  @monthly_data = Transaction.monthly_summary(6)
  @recent_transactions = Transaction.recent.limit(10)
  
  # Calculate this month's data
  month_start = Date.new(Date.today.year, Date.today.month, 1)
  month_end = Date.new(Date.today.year, Date.today.month, -1)
  @month_income = Transaction.total_income(month_start, month_end)
  @month_expenses = Transaction.total_expenses(month_start, month_end)
  
  erb :dashboard
end

get '/transactions' do
  @transactions = Transaction.recent
  erb :history
end

post '/transactions' do
  # Parse amount to ensure it is a valid decimal
  amount = params[:amount].to_f
  
  transaction = Transaction.new(
    description: params[:description],
    amount: amount,
    transaction_type: params[:transaction_type],
    category: params[:category],
    transaction_date: Date.parse(params[:transaction_date])
  )

  if transaction.save
    redirect '/'
  else
    # In a real app, we would render the form again with errors
    # For now, just redirect back
    redirect '/'
  end
end

post '/transactions/:id/delete' do
  transaction = Transaction.find(params[:id])
  transaction.destroy
  redirect back
end

post '/transactions/bulk-delete' do
  ids = params[:ids]
  if ids && ids.any?
    Transaction.where(id: ids).destroy_all
  end
  redirect back
end

# Helper methods
helpers do
  def partial(template, locals = {})
    erb :"partials/#{template}", { layout: false }, locals
  end

  def number_with_precision(number, options = {})
    precision = options[:precision] || 2
    delimiter = options[:delimiter] || ','
    
    parts = sprintf("%.#{precision}f", number).split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1#{delimiter}")
    parts.join('.')
  end
end
