class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.integer :warehouse_id
      t.integer :product_id
      t.integer :quantity_available

      t.timestamps
    end
  end
end
