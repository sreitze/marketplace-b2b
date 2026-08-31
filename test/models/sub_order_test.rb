require "test_helper"

class SubOrderTest < ActiveSupport::TestCase
  test "el subtotal persiste la suma de los items congelados" do
    # 2 x 15000 (teclado) + 1 x 8000 (mouse)
    assert_equal 38_000, sub_orders(:orden_acme).subtotal_cents
    assert_equal 90_000, sub_orders(:orden_globex).subtotal_cents
  end

  test "no permite dos subórdenes del mismo proveedor en una orden" do
    duplicada = SubOrder.new(order: orders(:orden), supplier: suppliers(:acme))

    assert_not duplicada.valid?
    assert_includes duplicada.errors.attribute_names, :supplier_id
  end

  test "rechaza un subtotal por debajo del mínimo de compra del proveedor" do
    sub_orden = sub_orders(:orden_globex)
    sub_orden.subtotal_cents = suppliers(:globex).minimum_purchase_cents - 1

    assert_not sub_orden.valid?
    assert_includes sub_orden.errors.attribute_names, :subtotal_cents
  end

  test "acepta un subtotal igual al mínimo de compra del proveedor" do
    sub_orden = sub_orders(:orden_globex)
    sub_orden.subtotal_cents = suppliers(:globex).minimum_purchase_cents

    assert sub_orden.valid?
  end

  test "permite el mismo proveedor en órdenes distintas" do
    otra_orden = Order.create!(store: stores(:tienda), total_cents: 0)
    sub_orden = SubOrder.new(order: otra_orden, supplier: suppliers(:acme))

    assert sub_orden.valid?
  end
end
