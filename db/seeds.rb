# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb

puts "=== Seeding products ==="

products_data = [
  {
    sku: "P001",
    name: "Surgical Gloves (Box of 100)",
    category: "Medical Supplies",
    requires_cold_chain: false
  },
  {
    sku: "P002",
    name: "Vaccine — Hepatitis B (10-dose vial)",
    category: "Pharmaceutical",
    requires_cold_chain: true
  },
  {
    sku: "P003",
    name: "Disposable Syringe (Box of 50)",
    category: "Medical Supplies",
    requires_cold_chain: false
  },
  {
    sku: "P004",
    name: "Vaccine — Tetanus Toxoid (10-dose vial)",
    category: "Pharmaceutical",
    requires_cold_chain: true
  },
  {
    sku: "P005",
    name: "Paracetamol Tablets (Box of 100)",
    category: "Pharmaceutical",
    requires_cold_chain: false
  }
]

products = {}

products_data.each do |attributes|
  product = Product.find_or_initialize_by(sku: attributes[:sku])
  product.assign_attributes(attributes)
  product.save!

  products[attributes[:sku]] = product
end

puts "Products seeded: #{products.size}"

# --------------------------------------------------
# Warehouses
# --------------------------------------------------

puts "=== Seeding warehouses ==="

warehouses_data = [
  {
    code: "W01",
    name: "Surabaya General Warehouse",
    city: "Surabaya",
    distance_km: 5,
    has_refrigerated_storage: false,
    has_refrigerated_vehicles: false,
    stock: {
      "P001" => 200,
      "P003" => 500,
      "P005" => 300
    }
  },
  {
    code: "W02",
    name: "Surabaya Refrigerated Warehouse",
    city: "Surabaya",
    distance_km: 12,
    has_refrigerated_storage: true,
    has_refrigerated_vehicles: false,
    stock: {
      "P001" => 50,
      "P002" => 30,
      "P004" => 20
    }
  },
  {
    code: "W03",
    name: "Sidoarjo General Warehouse",
    city: "Sidoarjo",
    distance_km: 25,
    has_refrigerated_storage: false,
    has_refrigerated_vehicles: false,
    stock: {
      "P001" => 300,
      "P003" => 200
    }
  },
  {
    code: "W04",
    name: "Gresik Refrigerated Warehouse",
    city: "Gresik",
    distance_km: 30,
    has_refrigerated_storage: true,
    has_refrigerated_vehicles: true,
    stock: {
      "P002" => 40,
      "P004" => 25,
      "P005" => 100
    }
  },
  {
    code: "W05",
    name: "Malang General Warehouse",
    city: "Malang",
    distance_km: 90,
    has_refrigerated_storage: false,
    has_refrigerated_vehicles: false,
    stock: {
      "P001" => 400,
      "P003" => 300,
      "P005" => 500
    }
  },
  {
    code: "W06",
    name: "Malang Refrigerated Warehouse",
    city: "Malang",
    distance_km: 95,
    has_refrigerated_storage: true,
    has_refrigerated_vehicles: false,
    stock: {
      "P002" => 20,
      "P004" => 30,
      "P003" => 100
    }
  },
  {
    code: "W07",
    name: "Pasuruan Refrigerated Warehouse",
    city: "Pasuruan",
    distance_km: 45,
    has_refrigerated_storage: true,
    has_refrigerated_vehicles: true,
    stock: {
      "P002" => 8,
      "P004" => 10,
      "P001" => 150
    }
  },
  {
    code: "W08",
    name: "Jember Refrigerated Warehouse",
    city: "Jember",
    distance_km: 150,
    has_refrigerated_storage: true,
    has_refrigerated_vehicles: true,
    stock: {
      "P002" => 60,
      "P004" => 50,
      "P005" => 200
    }
  }
]

warehouses_data.each do |attributes|
  stock_data = attributes.delete(:stock)

  warehouse = Warehouse.find_or_initialize_by(code: attributes[:code])
  warehouse.assign_attributes(attributes)
  warehouse.save!

  stock_data.each do |sku, quantity|
    product = products.fetch(sku)

    inventory = Inventory.find_or_initialize_by(
      warehouse_id: warehouse.id,
      product_id: product.id
    )

    inventory.quantity_available = quantity
    inventory.save!
  end

  puts "#{warehouse.code}: #{stock_data.size} inventory items seeded"
end

puts "=== Seeding completed ==="
puts "Products: #{Product.count}"
puts "Warehouses: #{Warehouse.count}"
puts "Inventory records: #{Inventory.count}"
