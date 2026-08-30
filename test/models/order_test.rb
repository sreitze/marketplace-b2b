require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "tiene una suborden por proveedor involucrado" do
    orden = orders(:orden)

    assert_equal 2, orden.sub_orders.count
    assert_equal [ suppliers(:acme), suppliers(:globex) ].sort_by(&:id),
                 orden.sub_orders.map(&:supplier).sort_by(&:id)
  end

  test "cada suborden agrupa sólo los items de su proveedor" do
    orden = orders(:orden)

    orden.sub_orders.each do |sub_orden|
      proveedores = sub_orden.order_items.map { |item| item.product.supplier }

      assert_equal [ sub_orden.supplier ], proveedores.uniq
    end
  end

  test "el total persiste la suma de los subtotales de todas las subórdenes" do
    assert_equal 128_000, orders(:orden).total_cents
  end

  test "el total no cambia cuando cambia el precio del producto" do
    orden = orders(:orden)
    total_original = orden.total_cents

    products(:teclado).update!(price_cents: 99_999)
    products(:monitor).update!(price_cents: 1)

    assert_equal total_original, Order.find(orden.id).total_cents
  end
end
