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

  test "rechaza una cantidad superior al stock disponible" do
    item = cart_items(:teclado_en_carrito)
    cap = item.product.stock + item.quantity
    item.quantity = cap + 1

    assert_not item.valid?
    assert_includes item.errors.attribute_names, :quantity
  end

  test "permite una cantidad igual al stock disponible, incluyendo lo que este item ya reservó" do
    item = cart_items(:teclado_en_carrito)
    item.quantity = item.product.stock + item.quantity

    assert item.valid?
  end

  test "usa el precio vigente del producto, no uno congelado" do
    item = cart_items(:teclado_en_carrito)
    assert_equal 30_000, item.subtotal_cents

    item.product.update!(price_cents: 20_000)

    assert_equal 40_000, item.reload.subtotal_cents
  end

  test "crear un cart item descuenta el stock reservado del producto" do
    item = CartItem.create!(cart: carts(:carrito_vacio), product: products(:mouse), quantity: 3)

    assert item.persisted?
    assert_equal 2, products(:mouse).reload.stock
  end

  test "aumentar la cantidad descuenta solo la diferencia del stock" do
    item = cart_items(:teclado_en_carrito)

    item.update!(quantity: 5)

    assert_equal 5, item.product.reload.stock
  end

  test "reducir la cantidad devuelve la diferencia al stock" do
    item = cart_items(:teclado_en_carrito)

    item.update!(quantity: 1)

    assert_equal 9, item.product.reload.stock
  end

  test "destruir un cart item devuelve toda su cantidad al stock" do
    item = cart_items(:teclado_en_carrito)

    item.destroy!

    assert_equal 10, products(:teclado).reload.stock
  end

  test "guardar sin cambiar la cantidad no mueve el stock" do
    item = cart_items(:teclado_en_carrito)

    item.save!

    assert_equal 8, item.product.reload.stock
  end

  test "una cantidad que excede el stock disponible no se guarda ni descuenta stock" do
    item = cart_items(:teclado_en_carrito)
    item.quantity = item.product.stock + item.quantity + 1

    assert_not item.save
    assert_equal 8, item.product.reload.stock
  end
end
