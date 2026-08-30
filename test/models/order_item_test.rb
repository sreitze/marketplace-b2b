require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  test "rechaza cantidad cero o negativa" do
    item = order_items(:teclado_comprado)

    [ 0, -1 ].each do |cantidad|
      item.quantity = cantidad

      assert_not item.valid?, "cantidad #{cantidad} no debería aceptarse"
      assert_includes item.errors.attribute_names, :quantity
    end
  end

  test "rechaza precio unitario negativo" do
    item = order_items(:teclado_comprado)
    item.unit_price_cents = -1

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :unit_price_cents
  end

  test "el subtotal usa el precio congelado y no el del catálogo" do
    item = order_items(:teclado_comprado)

    assert_equal 30_000, item.subtotal_cents

    item.product.update!(price_cents: 1)

    assert_equal 30_000, item.reload.subtotal_cents
    assert_equal 15_000, item.unit_price_cents
  end
end
