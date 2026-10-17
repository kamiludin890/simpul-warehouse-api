class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :status, null: false
      t.string :order_number
      t.integer :warehouse_id
      t.datetime :created_at, null: false
    end
  end
end
