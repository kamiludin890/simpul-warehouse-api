class Order < ApplicationRecord
    validates :status, presence: true
end
