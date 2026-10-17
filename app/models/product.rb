class Product < ApplicationRecord
    has_many :inventories
    has_many :warehouses, through: :inventories
    validates :name, :sku,:category, presence: true
    validates :sku, uniqueness: true
end
