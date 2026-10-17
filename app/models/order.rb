class Order < ApplicationRecord
    belongs_to :warehouse, optional: true
    has_many :order_items, dependent: :destroy
    accepts_nested_attributes_for :order_items

    validates :status, presence: true
end
