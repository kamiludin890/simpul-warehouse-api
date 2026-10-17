require "test_helper"

class Api::V1::InventoriesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "adds stock to an existing product at a warehouse" do
    warehouse = Warehouse.create!(
      code: "WH-JKT",
      name: "Gudang Jakarta",
      city: "Jakarta",
      distance_km: 12,
      has_refrigerated_storage: false,
      has_refrigerated_vehicles: false
    )
    product = Product.create!(
      name: "Test product",
      sku: "TEST-1",
      category: "test"
    )

    post api_v1_inventories_url,
         params: {
           inventory: {
             warehouse_id: warehouse.id,
             product_id: product.id,
             quantity: 3
           }
         },
         as: :json

    assert_response :created, response.body

    post api_v1_inventories_url,
         params: {
           inventory: {
             warehouse_id: warehouse.id,
             product_id: product.id,
             quantity: 4
           }
         },
         as: :json

    assert_response :success, response.body
    assert_equal 1, Inventory.count
    assert_equal 7, Inventory.sole.quantity_available
  end

  test "rejects non-positive stock additions" do
    post api_v1_inventories_url,
         params: {
           inventory: {
             warehouse_id: 1,
             product_id: 1,
             quantity: 0
           }
         },
         as: :json

    assert_response :unprocessable_entity
    assert_equal 0, Inventory.count
  end
end
