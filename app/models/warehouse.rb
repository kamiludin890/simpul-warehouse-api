class Warehouse < ApplicationRecord
    validates :code, :name,:city,:distance_km, :requires_cold_chain,:has_refrigerated_vehicles, presence: true
    validates :code, uniqueness: true
end
