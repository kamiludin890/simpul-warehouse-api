class OrderItem < ApplicationRecord
    validates :order_id, :product_id, :quantity, presence: true
    validates :quantity, numericality: {
    greater_than_or_equal_to: 0
    }
end
