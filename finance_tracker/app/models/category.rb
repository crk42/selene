class Category < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :category_type, presence: true, inclusion: { in: %w[income expense] }
end
