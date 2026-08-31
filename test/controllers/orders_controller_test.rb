require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include ApplicationHelper

  test "confirma la compra y redirige al detalle de la orden" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    post cart_items_path, params: { product_id: products(:monitor).id, quantity: 1 }

    post orders_path

    order = Order.last
    assert_redirected_to order_path(order)
    assert_not_nil flash[:notice]
    assert_equal 2, order.sub_orders.count
  end

  test "carrito vacío no puede confirmarse" do
    assert_no_difference "Order.count" do
      post orders_path
    end

    assert_redirected_to cart_path
    assert_not_nil flash[:alert]
  end

  test "muestra el detalle de la orden con subtotales por proveedor y total" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    post cart_items_path, params: { product_id: products(:monitor).id, quantity: 1 }
    post orders_path
    order = Order.last

    get order_path(order)

    assert_response :success
    assert_select "h2", text: suppliers(:acme).name
    assert_select "h2", text: suppliers(:globex).name
    assert_select "strong", text: "Total: #{format_money(order.total_cents)}"
  end

  test "orden inexistente devuelve 404" do
    get order_path(id: -1)

    assert_response :not_found
  end

  test "lista las órdenes de la tienda con fecha y total" do
    get orders_path

    assert_response :success
    assert_select "td", text: "##{orders(:orden).id}"
    assert_select "td", text: format_money(orders(:orden).total_cents)
  end
end
