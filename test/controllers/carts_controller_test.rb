require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  include ApplicationHelper

  test "muestra un carrito vacío sin romper cuando todavía no hay uno en sesión" do
    get cart_path

    assert_response :success
    assert_select "p", text: "El carrito está vacío."
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
end
