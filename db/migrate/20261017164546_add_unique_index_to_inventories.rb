class AddUniqueIndexToInventories < ActiveRecord::Migration[8.1]
  def change
    add_index :inventories, %i[warehouse_id product_id], unique: true
  end
end
