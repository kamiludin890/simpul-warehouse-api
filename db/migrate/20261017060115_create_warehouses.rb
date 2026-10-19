class CreateWarehouses < ActiveRecord::Migration[8.1]
  def change
    create_table :warehouses do |t|
      t.string :code
      t.string :name
      t.string :city
      t.decimal :distance_km
      t.boolean :has_refrigerated_storage
      t.boolean :has_refrigerated_vehicles

      t.timestamps
    end
  end
end
