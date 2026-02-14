require './app'

new_expenses = [
  "Canva", "Smart Rider", "Amazon", "Youtube", "sub", "Carl's Phone", 
  "my_love Phone", "Fuel", "Carl's Loan", "Mortgage", "Gym", "Food", 
  "my_love Insurance", "Gas", "Water", "Electricity", "Optus Home 5G", 
  "OpenAI Chat GPT", "Carls' Lunch/Coffee", "Mercedes Insurance", 
  "House Insurance", "Google storage", "Strata", "Council / Strata (monthly)", 
  "JB HI FI - protection", "Mercedes Licnces", "JP Trip", "Merc Service", "Savings"
]

puts "Adding new expense categories..."
new_expenses.each do |name|
  Category.find_or_create_by(name: name) do |c|
    c.category_type = 'expense'
  end
  puts "Added/Verified: #{name}"
end

puts "Done!"
