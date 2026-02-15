require 'sinatra'
require 'sinatra/json'
require 'active_record'
require 'json'
require 'date'

configure :development do
  require 'sinatra/reloader'
end

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/finance_tracker.db'
)

# Load Models
require_relative 'app/models/category'
require_relative 'app/models/transaction'

# Load Services
require_relative 'app/services/transaction_importer'

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
  
  # Calculate 6-month category breakdown
  six_month_start = Date.today << 5 # Go back 5 months + current month = 6 months
  six_month_start = Date.new(six_month_start.year, six_month_start.month, 1)
  @category_data_six_months = Transaction.category_expenses(six_month_start, month_end)
  
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

post '/transactions/:id' do
  transaction = Transaction.find(params[:id])
  
  amount = params[:amount].to_f
  
  if transaction
    transaction.update(
      description: params[:description],
      amount: amount,
      transaction_type: params[:transaction_type],
      category: params[:category],
      transaction_date: Date.parse(params[:transaction_date])
    )
  end

  redirect back
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

get '/categories/:category/transactions' do
  content_type :json
  category_name = params[:category]
  page = (params[:page] || 1).to_i
  per_page = 10
  offset = (page - 1) * per_page

  # Handle special case for "Uncategorized" or if category names are stored differently
  transactions = Transaction.where(category: category_name, transaction_type: 'expense')
  
  if params[:month] && params[:year]
    date = Date.new(params[:year].to_i, params[:month].to_i, 1)
    start_date = date
    end_date = Date.new(date.year, date.month, -1)
    transactions = transactions.where(transaction_date: start_date..end_date)
  else
    transactions = transactions.order(transaction_date: :desc)
  end

  total_count = transactions.count
  total_pages = (total_count / per_page.to_f).ceil
  
  paginated_transactions = transactions.limit(per_page).offset(offset)
  
  json({
    transactions: paginated_transactions,
    page: page,
    total_pages: total_pages,
    total_count: total_count
  })
end

post '/import' do
  if params[:file] && params[:file][:tempfile]
    file_path = params[:file][:tempfile]
    importer = TransactionImporter.new(file_path)
    count = importer.import
    
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

  def h(text)
    Rack::Utils.escape_html(text)
  end
end
