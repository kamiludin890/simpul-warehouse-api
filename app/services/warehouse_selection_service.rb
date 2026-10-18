
class WarehouseSelectionService
  class SelectionError < StandardError; end

  def initialize(items)
    @items = items.map do |item|
      {
        product_id: item[:product_id].to_i,
        quantity: item[:quantity].to_i
      }
    end
  end

  def call
    raise SelectionError, "Order items tidak boleh kosong" if @items.empty?

    if @items.any? { |item| item[:product_id] <= 0 || item[:quantity] <= 0 }
      raise SelectionError, "Product ID dan quantity harus valid"
    end

    # Gabungkan item dengan product_id yang sama.
    @items = @items
      .group_by { |item| item[:product_id] }
      .map do |product_id, items|
        { product_id: product_id, quantity: items.sum { |i| i[:quantity] } }
      end

    products = Product.where(id: @items.map { |i| i[:product_id] }).index_by(&:id)

    if products.size != @items.size
      raise SelectionError, "Ada produk yang tidak ditemukan"
    end

    warehouses = Warehouse.order(:distance_km, :id).to_a
    inventories_by_product = Inventory
      .includes(:warehouse)
      .where(product_id: @items.map { |item| item[:product_id] })
      .order(:id)
      .lock
      .to_a
      .group_by(&:product_id)

    allocations = {}

    @items.each do |item|
      product = products[item[:product_id]]
      inventory = warehouses.filter_map do |warehouse|
        next if product.requires_cold_chain == true &&
                !(warehouse.has_refrigerated_storage == true &&
                  warehouse.has_refrigerated_vehicles == true)

        candidate = inventories_by_product.fetch(item[:product_id], []).find do |record|
          record.warehouse_id == warehouse.id &&
            record.quantity_available >= item[:quantity]
        end

        candidate && [ warehouse, candidate ]
      end.first

      unless inventory
        raise SelectionError,
              "Tidak ada gudang yang memenuhi kebutuhan stok dan cold chain"
      end

      warehouse, inventory_record = inventory
      allocations[item[:product_id]] = {
        warehouse: warehouse,
        inventory: inventory_record,
        quantity: item[:quantity]
      }
    end

    allocations
  end
end
