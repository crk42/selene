require './app'

unless ActiveRecord::Base.connection.table_exists?(:categories)
  puts "Creating categories table..."
  ActiveRecord::Base.connection.create_table :categories do |t|
    t.string :name, null: false
    t.string :category_type, null: false
    t.timestamps
  end
  ActiveRecord::Base.connection.add_index :categories, :name, unique: true
end

puts "Seeding categories..."
defaults = {
  'income' => ['Salary', 'Freelance', 'Investment', 'Bonus', 'Gift', 'Other'],
  'expense' => ['Groceries', 'Rent', 'Utilities', 'Entertainment', 'Transportation', 'Healthcare', 'Shopping', 'Dining', 'Other']
}

defaults.each do |type, names|
  names.each do |name|
    Category.find_or_create_by(name: name, category_type: type)
  end
end

puts "Syncing existing transaction categories..."
Transaction.distinct.pluck(:category, :transaction_type).each do |cat_name, trans_type|
  next if cat_name.nil? || cat_name.empty? || cat_name == 'new_category_option'  # Skip if it's the UI temporary value
  
  # Ensure the category exists in the categories table with the correct type
  Category.find_or_create_by(name: cat_name) do |c|
    c.category_type = trans_type || 'expense' # Default to expense if type is missing
  end
end

puts "Done! Total categories: #{Category.count}"
