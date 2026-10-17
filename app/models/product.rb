class Product < ApplicationRecord
    validates :name, :sku,:category, presence: true
    validates :sku, uniqueness: true
end
