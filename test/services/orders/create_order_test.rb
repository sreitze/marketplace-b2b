require "test_helper"

class Orders::CreateOrderTest < ActiveSupport::TestCase
  test "agrupa los items del carrito en una suborden por proveedor" do
    cart = carts(:carrito_tienda)
    cart.cart_items.create!(product: products(:monitor), quantity: 1)

    order = Orders::CreateOrder.call(cart: cart)

    assert_equal 2, order.sub_orders.count

    acme_sub_order = order.sub_orders.find_by(supplier: suppliers(:acme))
    assert_equal [ products(:teclado) ], acme_sub_order.order_items.map(&:product)
    assert_equal 2, acme_sub_order.order_items.first.quantity
    assert_equal 15_000, acme_sub_order.order_items.first.unit_price_cents

    globex_sub_order = order.sub_orders.find_by(supplier: suppliers(:globex))
    assert_equal [ products(:monitor) ], globex_sub_order.order_items.map(&:product)
    assert_equal 1, globex_sub_order.order_items.first.quantity
    assert_equal 90_000, globex_sub_order.order_items.first.unit_price_cents
  end

  test "congela el precio del producto al momento de la compra" do
    order = Orders::CreateOrder.call(cart: carts(:carrito_tienda))
    order_item = order.order_items.first

    products(:teclado).update!(price_cents: 1)

    assert_equal 15_000, order_item.reload.unit_price_cents
  end

  test "rechaza confirmar un carrito vacío sin crear nada" do
    assert_no_difference [ "Order.count", "SubOrder.count", "OrderItem.count" ] do
      assert_raises(Orders::CreateOrder::EmptyCartError) do
        Orders::CreateOrder.call(cart: carts(:carrito_vacio))
      end
    end
  end

  test "un fallo a mitad de camino no deja orden ni suborden parcial" do
    # Las CHECK constraints de la base (quantity > 0, price_cents >= 0, etc.)
    # hacen imposible construir un CartItem o Product inválido incluso
    # bypasseando las validaciones de ActiveRecord. Para forzar un fallo real
    # a mitad del checkout hace falta parchear temporalmente price_cents.
    cart = carts(:carrito_tienda)
    cart.cart_items.create!(product: products(:monitor), quantity: 1)
    monitor_id = products(:monitor).id
    original_price_cents = Product.instance_method(:price_cents)

    Product.define_method(:price_cents) do
      id == monitor_id ? nil : original_price_cents.bind(self).call
    end

    assert_no_difference [ "Order.count", "SubOrder.count", "OrderItem.count" ] do
      assert_raises(ActiveRecord::RecordInvalid) do
        Orders::CreateOrder.call(cart: cart)
      end
    end

    assert_equal 2, cart.reload.cart_items.count
  ensure
    Product.define_method(:price_cents, original_price_cents) if original_price_cents
  end

  test "vacía el carrito sin liberar el stock ya reservado" do
    cart = carts(:carrito_tienda)

    Orders::CreateOrder.call(cart: cart)

    assert cart.reload.cart_items.empty?
    assert_equal 8, products(:teclado).reload.stock
  end
end
