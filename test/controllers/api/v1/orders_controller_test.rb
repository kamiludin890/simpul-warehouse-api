require "test_helper"

class Api::V1::OrdersControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "creates an order with selected products and quantities" do
    product = Product.create!(name: "Test product", sku: "TEST-1", category: "test")

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
    assert_equal product.id, response.parsed_body.dig("order_items", 0, "product_id")
    assert_equal 2, response.parsed_body.dig("order_items", 0, "quantity")
  end
end
