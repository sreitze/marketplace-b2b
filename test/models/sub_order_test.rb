require "test_helper"

class SubOrderTest < ActiveSupport::TestCase
  test "el subtotal suma los items congelados" do
    # 2 x 15000 (teclado) + 1 x 8000 (mouse)
    assert_equal 38_000, sub_orders(:orden_acme).subtotal_cents
    assert_equal 90_000, sub_orders(:orden_globex).subtotal_cents
  end

  test "no permite dos subórdenes del mismo proveedor en una orden" do
    duplicada = SubOrder.new(order: orders(:orden), supplier: suppliers(:acme))

    assert_not duplicada.valid?
    assert_includes duplicada.errors.attribute_names, :supplier_id
  end

  test "permite el mismo proveedor en órdenes distintas" do
    otra_orden = Order.create!(store: stores(:tienda))
    sub_orden = SubOrder.new(order: otra_orden, supplier: suppliers(:acme))

    assert sub_orden.valid?
  end
end
