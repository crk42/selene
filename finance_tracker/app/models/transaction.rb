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
