class CartsController < ApplicationController
  def show
    @cart_items_by_supplier = current_cart.cart_items.includes(product: :supplier).order(:id)
      .group_by { |item| item.product.supplier }
  end

  def destroy
    current_cart.cart_items.destroy_all
    redirect_to cart_path, notice: "Carrito vaciado."
  end
end
