class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :warehouse, optional: true

  validates :quantity,
            numericality: {
              only_integer: true,
              greater_than: 0
            }
end
