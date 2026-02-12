require './app'
begin
  cats = Category.all.map(&:name)
  puts "CATEGORIES_START"
  puts cats.join(',')
  puts "CATEGORIES_END"
  
  trans_cats = Transaction.select(:category).distinct.map(&:category).compact
  puts "TRANS_CATS_START"
  puts trans_cats.join(',')
  puts "TRANS_CATS_END"
rescue => e
  puts "ERROR: #{e.message}"
end
