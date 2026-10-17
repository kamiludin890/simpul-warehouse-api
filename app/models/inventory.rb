class Inventory < ApplicationRecord
    belongs_to :product
    belongs_to :warehouse
    validates :product_id, :warehouse_id, :quantity, presence: true
    validates :quantity, numericality: {
    greater_than_or_equal_to: 0
  }
end
