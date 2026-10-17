module Api
  module V1
    class InventoriesController < ApplicationController
      def index
        render json: Inventory.order(:warehouse_id, :product_id)
      end

      def create
        attributes = inventory_params
        quantity = attributes[:quantity]

        unless quantity.is_a?(Integer) && quantity.positive?
          return render json: {
            errors: [ "Jumlah stok harus berupa bilangan bulat positif" ]
          }, status: :unprocessable_entity
        end

        inventory = nil
        created = false

        Inventory.transaction do
          inventory = Inventory.lock.find_by(
            warehouse_id: attributes[:warehouse_id],
            product_id: attributes[:product_id]
          )

          if inventory
            inventory.update!(
              quantity_available: inventory.quantity_available + quantity
            )
          else
            begin
              inventory = Inventory.transaction(requires_new: true) do
                Inventory.create!(
                  warehouse_id: attributes[:warehouse_id],
                  product_id: attributes[:product_id],
                  quantity_available: quantity
                )
              end
              created = true
            rescue ActiveRecord::RecordNotUnique
              inventory = Inventory.lock.find_by!(
                warehouse_id: attributes[:warehouse_id],
                product_id: attributes[:product_id]
              )
              inventory.update!(
                quantity_available: inventory.quantity_available + quantity
              )
            end
          end
        end

        render json: inventory, status: created ? :created : :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages },
               status: :unprocessable_entity
      end

      private

      def inventory_params
        params.require(:inventory).permit(
          :warehouse_id,
          :product_id,
          :quantity
        )
      end
    end
  end
end
