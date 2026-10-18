class AddWarehouseToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :warehouse_id, :integer
    add_index :order_items, :warehouse_id
    add_foreign_key :order_items, :warehouses

    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE order_items
          SET warehouse_id = orders.warehouse_id
          FROM orders
          WHERE order_items.order_id = orders.id
            AND EXISTS (
              SELECT 1
              FROM warehouses
              WHERE warehouses.id = orders.warehouse_id
            )
        SQL
      end
    end
  end
end
