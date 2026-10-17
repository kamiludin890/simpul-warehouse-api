class Warehouse < ApplicationRecord
  validates :code, :name, :city, :distance_km, presence: true
  validates :distance_km, numericality: { greater_than_or_equal_to: 0 }
  validates :has_refrigerated_storage, :has_refrigerated_vehicles,
            inclusion: { in: [true, false] }
  validates :code, uniqueness: true
end
