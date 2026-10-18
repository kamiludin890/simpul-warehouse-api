
module Api
  module V1
    class OrdersController < ApplicationController
      before_action :set_order, only: %i[show update destroy]

      def index
        render json: Order.includes(
          :warehouse,
          order_items: %i[product warehouse]
        ),
               include: {
                 warehouse: {},
                 order_items: { include: %i[product warehouse] }
               }
      end

      def show
        render json: @order.as_json(
          include: {
            warehouse: {},
            order_items: { include: %i[product warehouse] }
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
          allocations = WarehouseSelectionService.new(items).call
          selected_warehouses = allocations.values.map { |item| item[:warehouse] }.uniq
          warehouse = selected_warehouses.one? ? selected_warehouses.first : nil

          # Buat order terlebih dahulu.
          order = Order.create!(
            warehouse: warehouse,
            status: "confirmed",
            order_number: "ORD-#{SecureRandom.hex(5).upcase}"
          )

          # Simpan detail pesanan dan kurangi stok.
          items.each do |item|
            allocation = allocations.fetch(item[:product_id])
            inventory = allocation[:inventory]

            order.order_items.create!(
              product_id: item[:product_id],
              quantity: item[:quantity],
              warehouse: allocation[:warehouse]
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
              order_items: { include: %i[product warehouse] }
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
        Order.transaction do
          @order.order_items.each do |order_item|
            inventory = Inventory.lock.find_by!(
              product_id: order_item.product_id,
              warehouse_id: order_item.warehouse_id || @order.warehouse_id
            )
            inventory.update!(
              quantity_available:
                inventory.quantity_available + order_item.quantity
            )
          end

          @order.destroy!
        end

        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: {
          errors: [ "Stok untuk salah satu item order tidak ditemukan" ]
        }, status: :unprocessable_entity
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
