module Api
  module V1
    class WarehousesController < ApplicationController
      before_action :set_warehouse, only: %i[show update destroy]

      def index
        render json: Warehouse.order(:id)
      end

      def show
        render json: @warehouse
      end

      def create
        warehouse = Warehouse.new(warehouse_params)

        if warehouse.save
          render json: warehouse, status: :created
        else
          render json: { errors: warehouse.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @warehouse.update(warehouse_params)
          render json: @warehouse
        else
          render json: { errors: @warehouse.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @warehouse.destroy!
        head :no_content
      end

      private

      def set_warehouse
        @warehouse = Warehouse.find(params[:id])
      end

      def warehouse_params
        params.require(:warehouse).permit(
          :code,
          :name,
          :city,
          :distance_km,
          :has_refrigerated_storage,
          :has_refrigerated_vehicles
        )
      end
    end
  end
end
