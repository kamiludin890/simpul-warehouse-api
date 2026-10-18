require "test_helper"

class Api::V1::OrdersControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "creates an order with selected products and quantities" do
    product = Product.create!(name: "Test product", sku: "TEST-1", category: "test")
    nearby_warehouse = create_warehouse(code: "NEAR", distance_km: 1)
    fallback_warehouse = create_warehouse(code: "FAR", distance_km: 10)
    Inventory.create!(
      product: product,
      warehouse: nearby_warehouse,
      quantity_available: 1
    )
    Inventory.create!(
      product: product,
      warehouse: fallback_warehouse,
      quantity_available: 5
    )

    post api_v1_orders_url,
         params: {
           order: {
             status: "pending",
             order_items: [
               { product_id: product.id, quantity: 2 }
             ]
           }
         },
         as: :json

    assert_response :created, response.body
    assert_equal 1, OrderItem.count
    order_item = response.parsed_body.dig("order", "order_items", 0)
    assert_equal product.id, order_item["product_id"]
    assert_equal 2, order_item["quantity"]
    assert_equal fallback_warehouse.id, order_item.dig("warehouse", "id")
    assert_equal 1, nearby_warehouse.inventories.find_by!(product: product).quantity_available
    assert_equal 3, fallback_warehouse.inventories.find_by!(product: product).quantity_available
  end

  test "allocates products from separate warehouses that meet their requirements" do
    standard_product = Product.create!(
      name: "Ambient product",
      sku: "AMBIENT-1",
      category: "test"
    )
    cold_product = Product.create!(
      name: "Cold product",
      sku: "COLD-1",
      category: "test",
      requires_cold_chain: true
    )
    nearby_warehouse = create_warehouse(code: "NEAR", distance_km: 1)
    cold_warehouse = create_warehouse(
      code: "COLD",
      distance_km: 2,
      has_refrigerated_storage: true,
      has_refrigerated_vehicles: true
    )
    [ standard_product, cold_product ].each do |product|
      Inventory.create!(
        product: product,
        warehouse: nearby_warehouse,
        quantity_available: 5
      )
      Inventory.create!(
        product: product,
        warehouse: cold_warehouse,
        quantity_available: 5
      )
    end

    post api_v1_orders_url,
         params: {
           order: {
             order_items: [
               { product_id: standard_product.id, quantity: 2 },
               { product_id: cold_product.id, quantity: 2 }
             ]
           }
         },
         as: :json

    assert_response :created, response.body
    order = response.parsed_body.fetch("order")
    assert_nil order["warehouse"]
    item_warehouses = order.fetch("order_items").index_by do |item|
      item["product_id"]
    end
    assert_equal nearby_warehouse.id,
                 item_warehouses.dig(standard_product.id, "warehouse", "id")
    assert_equal cold_warehouse.id,
                 item_warehouses.dig(cold_product.id, "warehouse", "id")
  end

  test "lists orders with their order items" do
    product = Product.create!(name: "Test product", sku: "TEST-1", category: "test")
    warehouse = create_warehouse(code: "LIST", distance_km: 1)
    order = Order.create!(status: "confirmed")
    order.order_items.create!(
      product: product,
      warehouse: warehouse,
      quantity: 2
    )

    get api_v1_orders_url, as: :json

    assert_response :success
    assert_equal product.id, response.parsed_body.first.dig("order_items", 0, "product_id")
    assert_equal 2, response.parsed_body.first.dig("order_items", 0, "quantity")
    assert_equal warehouse.id,
                 response.parsed_body.first.dig("order_items", 0, "warehouse", "id")
  end

  test "deletes an order and restores stock to the warehouses that supplied it" do
    first_product = Product.create!(
      name: "First product",
      sku: "FIRST-1",
      category: "test"
    )
    second_product = Product.create!(
      name: "Second product",
      sku: "SECOND-1",
      category: "test"
    )
    first_warehouse = create_warehouse(code: "FIRST", distance_km: 1)
    second_warehouse = create_warehouse(code: "SECOND", distance_km: 2)
    first_inventory = Inventory.create!(
      product: first_product,
      warehouse: first_warehouse,
      quantity_available: 3
    )
    second_inventory = Inventory.create!(
      product: second_product,
      warehouse: second_warehouse,
      quantity_available: 4
    )
    order = Order.create!(status: "confirmed")
    order.order_items.create!(
      product: first_product,
      warehouse: first_warehouse,
      quantity: 2
    )
    order.order_items.create!(
      product: second_product,
      warehouse: second_warehouse,
      quantity: 1
    )
    first_inventory.update!(quantity_available: 1)
    second_inventory.update!(quantity_available: 3)

    delete api_v1_order_url(order), as: :json

    assert_response :no_content
    assert_not Order.exists?(order.id)
    assert_equal 0, OrderItem.where(order_id: order.id).count
    assert_equal 3, first_inventory.reload.quantity_available
    assert_equal 4, second_inventory.reload.quantity_available
  end

  test "deletes a legacy order using its warehouse when an item has no warehouse" do
    product = Product.create!(name: "Legacy product", sku: "LEGACY-1", category: "test")
    warehouse = create_warehouse(code: "LEGACY", distance_km: 1)
    inventory = Inventory.create!(
      product: product,
      warehouse: warehouse,
      quantity_available: 3
    )
    order = Order.create!(status: "confirmed", warehouse: warehouse)
    order.order_items.create!(product: product, quantity: 2)

    delete api_v1_order_url(order), as: :json

    assert_response :no_content
    assert_equal 5, inventory.reload.quantity_available
  end

  test "does not delete an order or partially restore stock when inventory is missing" do
    first_product = Product.create!(
      name: "Available product",
      sku: "AVAILABLE-1",
      category: "test"
    )
    missing_product = Product.create!(
      name: "Missing inventory product",
      sku: "MISSING-1",
      category: "test"
    )
    warehouse = create_warehouse(code: "ROLLBACK", distance_km: 1)
    inventory = Inventory.create!(
      product: first_product,
      warehouse: warehouse,
      quantity_available: 1
    )
    order = Order.create!(status: "confirmed")
    order.order_items.create!(
      product: first_product,
      warehouse: warehouse,
      quantity: 2
    )
    order.order_items.create!(
      product: missing_product,
      warehouse: warehouse,
      quantity: 1
    )

    delete api_v1_order_url(order), as: :json

    assert_response :unprocessable_entity
    assert_equal [ "Stok untuk salah satu item order tidak ditemukan" ],
                 response.parsed_body.fetch("errors")
    assert Order.exists?(order.id)
    assert_equal 2, OrderItem.where(order_id: order.id).count
    assert_equal 1, inventory.reload.quantity_available
  end

  private

  def create_warehouse(
    code:,
    distance_km:,
    has_refrigerated_storage: false,
    has_refrigerated_vehicles: false
  )
    Warehouse.create!(
      code: code,
      name: "Warehouse #{code}",
      city: "Test city",
      distance_km: distance_km,
      has_refrigerated_storage: has_refrigerated_storage,
      has_refrigerated_vehicles: has_refrigerated_vehicles
    )
  end
end
