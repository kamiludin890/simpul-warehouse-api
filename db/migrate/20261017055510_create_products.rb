class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :sku
      t.string :category
      t.boolean :requires_cold_chain
      t.timestamps
    end
  end
end
