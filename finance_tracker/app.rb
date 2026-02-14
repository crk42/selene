require 'sinatra'
require 'sinatra/json'
require 'active_record'
require 'json'
require 'date'
require 'csv'

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/finance_tracker.db'
)

# Category model
class Category < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :category_type, presence: true, inclusion: { in: %w[income expense] }
end

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

  def self.category_expenses(start_date = nil, end_date = nil)
    scope = expense
    scope = scope.where(transaction_date: start_date..end_date) if start_date && end_date
    scope.group(:category).sum(:amount)
  end
end

# Seed categories if empty
if ActiveRecord::Base.connection.table_exists?(:categories) && Category.count == 0
  puts "Seeding default categories..."
  defaults = {
    'income' => ['Salary', 'Freelance', 'Investment', 'Bonus', 'Gift', 'Other'],
    'expense' => ['Groceries', 'Rent', 'Utilities', 'Entertainment', 'Transportation', 'Healthcare', 'Shopping', 'Dining', 'Other']
  }
  
  defaults.each do |type, names|
    names.each do |name|
      Category.create(name: name, category_type: type)
    end
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
  @category_data = Transaction.category_expenses(month_start, month_end)
  @categories = Category.all.group_by(&:category_type) rescue {}
  
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

get '/categories' do
  content_type :json
  categories = Category.all.group_by(&:category_type)
  categories.to_json
end

post '/categories' do
  name = params[:name]
  type = params[:type]
  
  if name && type
    category = Category.new(name: name, category_type: type)
    if category.save
      status 201
      json category
    else
      status 422
      json({ error: category.errors.full_messages })
    end
  else
    status 400
    json({ error: "Missing name or type" })
  end
end

post '/import' do
  if params[:file] && params[:file][:tempfile]
    file = params[:file][:tempfile]
    count = 0
    
    # Keyword mapping for categorization
    keywords = {
      'groceries' => ['woolworths', 'coles', 'aldi', 'iga', 'food'],
      'transportation' => ['uber', 'did', 'ola', 'taxi', 'train', 'bus', 'opal', 'myki', 'fuel', 'petrol', 'bp', 'shell', '7-eleven', 'caltex', 'ampol'],
      'dining' => ['restaurant', 'cafe', 'coffee', 'mcdonalds', 'kfc', 'hungry jacks', 'dominos', 'pizza', 'burger', 'sushi', 'grill', 'eats', 'menulog', 'doordash'],
      'utilities' => ['energy', 'water', 'gas', 'telecom', 'internet', 'telstra', 'optus', 'vodafone', 'electricity'],
      'entertainment' => ['netflix', 'spotify', 'movie', 'cinema', 'steam', 'playstation', 'xbox', 'nintendo'],
      'healthcare' => ['pharmacy', 'chemist', 'doctor', 'medical', 'dental', 'hospital', 'medicare'],
      'shopping' => ['kmart', 'target', 'big w', 'myer', 'david jones', 'amazon', 'ebay', 'ikea', 'bunnings']
    }

    CSV.foreach(file, headers: false) do |row|
      # CBA Format: Date, Amount, Description, Balance
      # Example: 13/02/2026,"-75.00","Transfer To Ubank Saver - New App 2022 CommBank App food","+24.41"
      
      next if row.length < 3 || row[0].nil? # Skip invalid rows
      
      begin
        date_str = row[0]
        amount_str = row[1].gsub(',', '')
        description = row[2]
        
        # Parse date (DD/MM/YYYY)
        transaction_date = Date.strptime(date_str, '%d/%m/%Y')
        
        # Parse amount and type
        amount_val = amount_str.to_f
        transaction_type = amount_val < 0 ? 'expense' : 'income'
        amount = amount_val.abs
        
        # Auto-categorize
        category = 'Other' # Default
        if transaction_type == 'income'
          category = 'Salary' if description.downcase.include?('salary') || description.downcase.include?('wages')
        else
          desc_lower = description.downcase
          
          # Check keyword mapping
          keywords.each do |cat_key, terms|
            if terms.any? { |term| desc_lower.include?(term) }
              category = cat_key.capitalize
              break
            end
          end
        end
        
        # Check for duplicates using existing transaction check
        # Avoid creating if same date, amount, description exists
        unless Transaction.exists?(transaction_date: transaction_date, amount: amount, description: description)
          Transaction.create!(
            transaction_date: transaction_date,
            amount: amount,
            description: description,
            transaction_type: transaction_type,
            category: category
          )
          count += 1
        end
        
      rescue => e
        puts "Error parsing row: #{row.inspect} - #{e.message}"
        next
      end
    end
    
    redirect "/?imported=#{count}"
  else
    redirect '/'
  end
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
