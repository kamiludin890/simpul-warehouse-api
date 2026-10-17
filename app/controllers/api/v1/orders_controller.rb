module Api
  module V1
    class OrdersController < ApplicationController
        before_action :set_order, only: %i[show update destroy]

        def index
            render json: Order.all
        end

        def show
            render json: @order
        end

        def create
            order = Order.new(order_params)

            if order.save
                render json: order, status: :created
            else
                render json: {
                    errors: order.errors.full_messages
                }, status: :unprocessable_entity
            end
        end
        def update
            if @order.update(order_params)
                render json: @order
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
                :status
            )
        end

    end
end