class CreateWarehouseItems < ActiveRecord::Migration[8.1]
  def change
    create_table :warehouse_items do |t|
      t.integer :product_id
      t.integer :qty

      t.timestamps
    end
  end
end
