class CartsController < ApplicationController
  def show
    @cart_items = current_cart.cart_items.includes(product: :supplier).order(:id)
  end

  def destroy
    current_cart.cart_items.destroy_all
    redirect_to cart_path, notice: "Carrito vaciado."
  end
end
