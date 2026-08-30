require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  include ApplicationHelper

  test "muestra un carrito vacío sin romper cuando todavía no hay uno en sesión" do
    get cart_path

    assert_response :success
    assert_select "p", text: "El carrito está vacío."
  end

  test "no muestra el botón Confirmar cuando el carrito está vacío" do
    get cart_path

    assert_select "form[action=?]", orders_path, count: 0
  end

  test "muestra el botón Confirmar cuando el carrito tiene items" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }

    get cart_path

    assert_select "form[action=?]", orders_path
  end

  test "muestra los items del carrito con su total" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 2 }
    post cart_items_path, params: { product_id: products(:monitor).id, quantity: 1 }

    get cart_path

    assert_response :success
    assert_select "td", text: products(:teclado).name
    assert_select "td", text: products(:monitor).name
    assert_select "strong", text: "Total: #{format_money(2 * products(:teclado).price_cents + products(:monitor).price_cents)}"
  end

  test "vaciar el carrito elimina todos los items y redirige al carrito" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 2 }
    post cart_items_path, params: { product_id: products(:monitor).id, quantity: 1 }
    cart = Cart.find(session[:cart_id])

    delete cart_path

    assert_redirected_to cart_path
    assert_equal 0, cart.cart_items.count
  end

  test "vaciar el carrito devuelve el stock reservado de cada item" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 2 }
    post cart_items_path, params: { product_id: products(:monitor).id, quantity: 1 }

    delete cart_path

    assert_equal 8, products(:teclado).reload.stock
    assert_equal 3, products(:monitor).reload.stock
  end

  test "no crea orden ni suborden al vaciar el carrito" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }

    assert_no_difference [ "Order.count", "SubOrder.count" ] do
      delete cart_path
    end
  end
end
