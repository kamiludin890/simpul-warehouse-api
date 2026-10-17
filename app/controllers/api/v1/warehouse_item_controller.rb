module Api
    module V1
        class WarehouseController < ApplicationController
            before_action :set_warehouse_item, only: %i[show update destroy]

        def index
            render json: WarehouseItem.all
        end

        def show
            render json: @warehouse_item
        end

        def create
            warehouse_item = Warehouse_item.new(warehouse_item_params)
            if warehouse_item.save
                render json: warehouse_item, status: :create
            else
                render json: {
                    error: warehouse_item.errors.full_messages
                }, status: :unprocessable_entity
            end
        end

        def update
            if @warehouse_item.update(warehouse_item_params)
                render json: @warehouse_item
            else
                render json: {
                errors: @warehouse_item.errors.full_messages
                }, status: :unprocessable_entity
            end
        end
        def destroy
            @warehouse_item.destroy!
            head :no_content
        end
        private

        def set_product
            @product = Product.find(params[:id])
        end

        def product_params
            params.require(:product).permit(
            :name, :sku, :category
            )
        end
        end
    end
end