
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

    # Urutkan kandidat dari gudang terdekat.
    warehouses = Warehouse.order(:distance_km, :id)

    warehouses.each do |warehouse|
      # Cold chain wajib memenuhi kedua syarat.
      needs_cold_chain = @items.any? do |item|
        products[item[:product_id]].requires_cold_chain == true
      end

      if needs_cold_chain &&
         !(warehouse.has_refrigerated_storage == true &&
           warehouse.has_refrigerated_vehicles == true)
        next
      end

      inventories = Inventory
        .where(
          warehouse_id: warehouse.id,
          product_id: @items.map { |i| i[:product_id] }
        )
        .index_by(&:product_id)

      # Semua produk dan jumlahnya harus tersedia di gudang yang sama.
      enough_stock = @items.all? do |item|
        inventory = inventories[item[:product_id]]
        inventory && inventory.quantity_available >= item[:quantity]
      end

      return warehouse if enough_stock
    end

    raise SelectionError,
          "Tidak ada gudang yang memenuhi kebutuhan stok dan cold chain"
  end
end
