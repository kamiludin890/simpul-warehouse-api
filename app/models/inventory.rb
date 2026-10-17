class Inventory < ApplicationRecord
  belongs_to :product
  belongs_to :warehouse

  validates :quantity_available, presence: true, numericality: {
    greater_than_or_equal_to: 0
  }
end
