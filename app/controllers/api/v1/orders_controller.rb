
module Api
  module V1
    class OrdersController < ApplicationController
      before_action :set_order, only: %i[show update destroy]

      def index
        render json: Order.includes(:warehouse, order_items: :product)
      end

      def show
        render json: @order.as_json(
          include: {
            warehouse: {},
            order_items: { include: :product }
          }
        )
      end

      def create
        items = order_params[:order_items_attributes]

        raise WarehouseSelectionService::SelectionError,
              "Order items tidak boleh kosong" if items.blank?

        # Gabungkan item dengan product_id yang sama.
        items = items.group_by { |item| item[:product_id].to_i }
                     .map do |product_id, product_items|
          {
            product_id: product_id,
            quantity: product_items.sum do |item|
              item[:quantity].to_i
            end
          }
        end

        order = nil

        Order.transaction do
          # Pilih gudang yang memenuhi kebutuhan pesanan.
          warehouse = WarehouseSelectionService.new(items).call

          # Kunci baris inventory untuk mencegah race condition.
          inventories = Inventory
            .where(
              warehouse_id: warehouse.id,
              product_id: items.map { |item| item[:product_id] }
            )
            .order(:id)
            .lock
            .to_a

          inventory_by_product = inventories.index_by(&:product_id)

          # Validasi ulang stok setelah baris dikunci.
          items.each do |item|
            inventory = inventory_by_product[item[:product_id]]

            unless inventory &&
                   inventory.quantity_available >= item[:quantity]
              raise WarehouseSelectionService::SelectionError,
                    "Stok berubah atau tidak mencukupi. Silakan coba lagi."
            end
          end

          # Buat order terlebih dahulu.
          order = Order.create!(
            warehouse: warehouse,
            status: "confirmed",
            order_number: "ORD-#{SecureRandom.hex(5).upcase}"
          )

          # Simpan detail pesanan dan kurangi stok.
          items.each do |item|
            inventory = inventory_by_product.fetch(item[:product_id])

            order.order_items.create!(
              product_id: item[:product_id],
              quantity: item[:quantity]
            )

            inventory.update!(
              quantity_available:
                inventory.quantity_available - item[:quantity]
            )
          end
        end

        render json: {
          message: "Order berhasil dibuat",
          order: order.as_json(
            include: {
              warehouse: {},
              order_items: { include: :product }
            }
          )
        }, status: :created

      rescue WarehouseSelectionService::SelectionError => e
        render json: { errors: [e.message] },
               status: :unprocessable_entity

      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages },
               status: :unprocessable_entity
      end

      def update
        if @order.update(order_params)
          render json: @order, include: :order_items
        else
          render json: {
            errors: @order.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        @order.destroy!
        head :no_content
      end

      private

      def set_order
        @order = Order.find(params[:id])
      end

      def order_params
        params.require(:order).permit(
          order_items: %i[product_id quantity]
        ).tap do |permitted|
          permitted[:order_items_attributes] =
            permitted.delete(:order_items)
        end
      end
    end
  end
end
