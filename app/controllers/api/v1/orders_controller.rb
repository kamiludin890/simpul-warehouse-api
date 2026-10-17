module Api
  module V1
    class OrdersController < ApplicationController
      before_action :set_order, only: %i[show update destroy]

      def index
        render json: Order.includes(:order_items), include: :order_items
      end

      def show
        render json: @order, include: :order_items
      end

      def create
        order = Order.new(order_params)

        if order.save
          render json: order, include: :order_items, status: :created
        else
          render json: {
            errors: order.errors.full_messages
          }, status: :unprocessable_entity
        end
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
        permitted = params.require(:order).permit(
          :status,
          order_items: %i[product_id quantity]
        )
        permitted[:order_items_attributes] = permitted.delete(:order_items) if permitted.key?(:order_items)
        permitted
      end
    end
  end
end
