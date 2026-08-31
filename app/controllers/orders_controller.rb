class OrdersController < ApplicationController
  def create
    order = Orders::CreateOrder.call(cart: current_cart)
    redirect_to order_path(order), notice: "Compra confirmada."
  rescue Orders::CreateOrder::EmptyCartError
    redirect_to cart_path, alert: "El carrito está vacío."
  end

  def index
    @orders = current_store.orders.order(created_at: :desc)
  end

  def show
    @order = current_store.orders
                           .includes(sub_orders: [ :supplier, { order_items: :product } ])
                           .find(params[:id])
  end
end
