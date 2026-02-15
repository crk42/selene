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

    is_io = @file_path.respond_to?(:read)
    
    # Read first line to detect format
    first_line = ''
    if is_io
      @file_path.rewind if @file_path.respond_to?(:rewind)
      first_line = @file_path.readline.strip rescue ''
      @file_path.rewind if @file_path.respond_to?(:rewind)
    else
      first_line = File.open(@file_path, &:readline).strip rescue ''
    end
    
    # Remove BOM if present
    first_line = first_line.sub("\xEF\xBB\xBF", "")
    
    # Check for export format using regex to handle potential quotes or whitespace
    # Matches: ID, Date, Description, Amount, Type, Category (case insensitive, allowing surrounding characters)
    is_export_format = first_line.match?(/ID.*Date.*Description.*Amount.*Type.*Category/i)
    
    csv_options = is_export_format ? { headers: true, header_converters: lambda { |h| h.strip } } : { headers: false }

    # Define processing block to avoid duplication
    process_row = lambda do |row|
      begin
        if is_export_format
          # ID,Date,Description,Amount,Type,Category
          # Example: 1,2026-02-15,Groceries,50.0,expense,Groceries
          
          if row['Date'].nil?
            return
          end

          transaction_date = Date.parse(row['Date'])
          amount = row['Amount'].to_f
          description = row['Description']
          transaction_type = row['Type']
          category = row['Category']
          
        else
          # CBA Format: Date, Amount, Description, Balance
          
          return if row.length < 3 || row[0].nil? # Skip invalid rows
          
          date_str = row[0]
          amount_str = row[1].gsub(',', '')
          description = row[2]
          description = description.gsub(/Value Date: \d{2}\/\d{2}\/\d{2}/, '').strip
          
          transaction_date = Date.strptime(date_str, '%d/%m/%Y')
          
          amount_val = amount_str.to_f
          transaction_type = amount_val < 0 ? 'expense' : 'income'
          amount = amount_val.abs
          
          category = categorize(description, transaction_type)
        end
        
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
      end
    end

    if is_io
       CSV.new(@file_path, **csv_options).each(&process_row)
    else
       CSV.foreach(@file_path, **csv_options, &process_row)
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
