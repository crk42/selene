class Transaction < ApplicationRecord
  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense] }
  validates :transaction_date, presence: true

  scope :income, -> { where(transaction_type: 'income') }
  scope :expense, -> { where(transaction_type: 'expense') }
  scope :recent, -> { order(transaction_date: :desc) }
  scope :by_month, ->(date) { where(transaction_date: date.beginning_of_month..date.end_of_month) }

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
      date = i.months.ago
      month_start = date.beginning_of_month
      month_end = date.end_of_month
      
      results << {
        month: date.strftime('%B %Y'),
        income: total_income(month_start, month_end),
        expenses: total_expenses(month_start, month_end),
        balance: balance(month_start, month_end)
      }
    end
    results.reverse
  end
end
