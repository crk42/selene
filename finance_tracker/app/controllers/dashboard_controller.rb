class DashboardController < ApplicationController
  def index
    @total_income = Transaction.total_income
    @total_expenses = Transaction.total_expenses
    @current_balance = Transaction.balance
    
    @monthly_data = Transaction.monthly_summary(6)
    @recent_transactions = Transaction.recent.limit(10)
    
    # Calculate this month's data
    month_start = Date.today.beginning_of_month
    month_end = Date.today.end_of_month
    @month_income = Transaction.total_income(month_start, month_end)
    @month_expenses = Transaction.total_expenses(month_start, month_end)
  end
end
