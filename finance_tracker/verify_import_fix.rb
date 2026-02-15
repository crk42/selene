
require './app'
require './app/services/transaction_importer'
require 'stringio'

def test_import(name, csv_content)
  puts "\n--- Testing #{name} ---"
  s = StringIO.new(csv_content)
  importer = TransactionImporter.new(s)
  count = importer.import
  puts "Imported: #{count}"
  if count == 1
    puts "SUCCESS"
  else
    puts "FAILURE: Expected 1, got #{count}"
  end
end

# 1. Standard
test_import("Standard Headers", <<~CSV)
ID,Date,Description,Amount,Type,Category
9001,2026-02-15,TestStandard,100.0,expense,TestCat
CSV

# 2. Quoted
test_import("Quoted Headers", <<~CSV)
"ID","Date","Description","Amount","Type","Category"
"9002","2026-02-15","TestQuoted","100.0","expense","TestCat"
CSV

# 3. Spaced
test_import("Spaced Headers", <<~CSV)
ID, Date, Description, Amount, Type, Category
9003,2026-02-15,TestSpaced,100.0,expense,TestCat
CSV

# Cleanup
Transaction.where(description: ['TestStandard', 'TestQuoted', 'TestSpaced']).destroy_all
