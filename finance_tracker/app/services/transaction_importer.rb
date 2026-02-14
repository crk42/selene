require 'csv'
require 'date'

class TransactionImporter
  KEYWORDS = {
    'groceries' => ['woolworths', 'coles', 'aldi', 'iga', 'food', 'market', 'grocer'],
    'transportation' => ['uber', 'did', 'ola', 'taxi', 'train', 'bus', 'opal', 'myki', 'fuel', 'petrol', 'bp', 'shell', '7-eleven', 'caltex', 'ampol', 'service station', 'united'],
    'dining' => ['restaurant', 'cafe', 'coffee', 'mcdonalds', 'kfc', 'hungry jacks', 'dominos', 'pizza', 'burger', 'sushi', 'grill', 'eats', 'menulog', 'doordash', 'lunch', 'dinner'],
    'utilities' => ['energy', 'water', 'gas', 'telecom', 'internet', 'telstra', 'optus', 'vodafone', 'electricity', 'agl', 'origin'],
    'entertainment' => ['netflix', 'spotify', 'movie', 'cinema', 'steam', 'playstation', 'xbox', 'nintendo', 'game', 'disney', 'prime', 'canva', 'youtube', 'sub'],
    'healthcare' => ['pharmacy', 'chemist', 'doctor', 'medical', 'dental', 'hospital', 'medicare'],
    'shopping' => ['kmart', 'target', 'big w', 'myer', 'david jones', 'amazon', 'ebay', 'ikea', 'bunnings', 'jb hi fi', 'retail'],
    'mortgage' => ['mortgage', 'loan repayment', 'home loan'],
    'rent' => ['rent'],
    'gym' => ['gym', 'fitness', 'anytime', 'workout'],
    'insurance' => ['insurance', 'policy', 'premium', 'medibank', 'bupa', 'aami', 'nrma', 'racv', 'g i o', 'allianz'],
    'savings' => ['savings', 'saver', 'term deposit', 'wealth', 'invest'],
    'strata' => ['strata', 'body corp'],
    'phone' => ['phone', 'mobile'],
    'service' => ['service', 'mechanic', 'auto']
  }.freeze

  def initialize(file_path)
    @file_path = file_path
  end

  def import
    count = 0
    
    CSV.foreach(@file_path, headers: false) do |row|
      # CBA Format: Date, Amount, Description, Balance
      # Example: 13/02/2026,"-75.00","Transfer To Ubank Saver - New App 2022 CommBank App food","+24.41"
      
      next if row.length < 3 || row[0].nil? # Skip invalid rows
      
      begin
        date_str = row[0]
        amount_str = row[1].gsub(',', '')
        description = row[2]
        description = description.gsub(/Value Date: \d{2}\/\d{2}\/\d{2}/, '').strip
        
        # Parse date (DD/MM/YYYY)
        transaction_date = Date.strptime(date_str, '%d/%m/%Y')
        
        # Parse amount and type
        amount_val = amount_str.to_f
        transaction_type = amount_val < 0 ? 'expense' : 'income'
        amount = amount_val.abs
        
        # Auto-categorize
        category = categorize(description, transaction_type)
        
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
    
    count
  end

  private

  def categorize(description, type)
    return 'Other' unless type == 'expense' || (type == 'income' && (description.downcase.include?('salary') || description.downcase.include?('wages')))
    return 'Salary' if type == 'income'

    desc_lower = description.downcase
    
    KEYWORDS.each do |cat_key, terms|
      if terms.any? { |term| desc_lower.include?(term) }
        return cat_key.capitalize
      end
    end
    
    'Other'
  end
end
