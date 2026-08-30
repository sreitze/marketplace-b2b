require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  test "es válido con cantidad entera positiva" do
    assert cart_items(:teclado_en_carrito).valid?
  end

  test "rechaza cantidad cero" do
    item = cart_items(:teclado_en_carrito)
    item.quantity = 0

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :quantity
  end

  test "rechaza cantidad negativa" do
    item = cart_items(:teclado_en_carrito)
    item.quantity = -3

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :quantity
  end

  test "rechaza cantidad no entera" do
    item = cart_items(:teclado_en_carrito)
    item.quantity = 1.5

    assert_not item.valid?, "1.5 no debería aceptarse como cantidad"
    assert_includes item.errors.attribute_names, :quantity
  end

  test "rechaza cantidad no entera enviada como texto desde un formulario" do
    item = cart_items(:teclado_en_carrito)
    item.quantity = "1.5"

    assert_not item.valid?, "\"1.5\" no debería aceptarse como cantidad"
    assert_includes item.errors.attribute_names, :quantity
  end

  test "no permite el mismo producto dos veces en el mismo carrito" do
    duplicado = CartItem.new(cart: carts(:carrito_tienda), product: products(:teclado), quantity: 1)

    assert_not duplicado.valid?
    assert_includes duplicado.errors.attribute_names, :product_id
  end

  test "permite el mismo producto en carritos distintos" do
    otro = CartItem.new(cart: carts(:carrito_vacio), product: products(:teclado), quantity: 1)

    assert otro.valid?
  end

  test "usa el precio vigente del producto, no uno congelado" do
    item = cart_items(:teclado_en_carrito)
    assert_equal 30_000, item.subtotal_cents

    item.product.update!(price_cents: 20_000)

    assert_equal 40_000, item.reload.subtotal_cents
  end
end
