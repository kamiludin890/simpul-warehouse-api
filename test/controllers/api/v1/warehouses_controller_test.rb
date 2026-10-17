require "test_helper"

class Api::V1::WarehousesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "creates a warehouse including false refrigeration flags" do
    post api_v1_warehouses_url,
         params: {
           warehouse: {
             code: "WH-JKT",
             name: "Gudang Jakarta",
             city: "Jakarta",
             distance_km: 12,
             has_refrigerated_storage: false,
             has_refrigerated_vehicles: false
           }
         },
         as: :json

    assert_response :created, response.body
    assert_equal "WH-JKT", response.parsed_body["code"]
    assert_equal false, response.parsed_body["has_refrigerated_storage"]
    assert_equal false, response.parsed_body["has_refrigerated_vehicles"]
  end

  test "updates a warehouse" do
    warehouse = Warehouse.create!(
      code: "WH-BDG",
      name: "Gudang Bandung",
      city: "Bandung",
      distance_km: 20,
      has_refrigerated_storage: false,
      has_refrigerated_vehicles: true
    )

    patch api_v1_warehouse_url(warehouse),
          params: { warehouse: { distance_km: 25 } },
          as: :json

    assert_response :success
    assert_equal 25, response.parsed_body["distance_km"]
  end
end
