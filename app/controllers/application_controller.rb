class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_cart

  private

  # Sin autenticación: la única tienda de los seeds. Aislado en un método
  # para que se vea dónde entraría un usuario real más adelante.
  def current_store
    Store.first
  end

  def current_cart
    @current_cart ||= find_or_create_cart
  end

  def find_or_create_cart
    cart = current_store.carts.find_by(id: session[:cart_id])
    cart ||= current_store.carts.create!.tap { |c| session[:cart_id] = c.id }
    cart
  end
end
