class CartItemsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    item = current_cart.add_product(product, params[:quantity].presence || 1)

    if item.errors.empty?
      redirect_to cart_path, notice: "#{product.name} agregado al carrito."
    else
      redirect_to root_path, alert: item.errors.full_messages.to_sentence
    end
  end

  def update
    cart_item = current_cart.cart_items.find(params[:id])

    if cart_item.update(quantity: params[:quantity])
      redirect_to cart_path, notice: "Cantidad actualizada."
    else
      redirect_to cart_path, alert: cart_item.errors.full_messages.to_sentence
    end
  end

  def destroy
    cart_item = current_cart.cart_items.find(params[:id])
    cart_item.destroy

    redirect_to cart_path, notice: "Producto eliminado del carrito."
  end
end
