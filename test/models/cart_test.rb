require "test_helper"

class CartTest < ActiveSupport::TestCase
  test "agrega un producto nuevo al carrito" do
    cart = carts(:carrito_vacio)

    item = cart.add_product(products(:mouse), 3)

    assert item.persisted?
    assert_equal 3, item.quantity
  end

  test "agregar el mismo producto dos veces suma cantidades en vez de duplicar el item" do
    cart = carts(:carrito_tienda)

    item = cart.add_product(products(:teclado), 5)

    assert_equal 7, item.reload.quantity
    assert_equal 1, cart.cart_items.where(product: products(:teclado)).count
  end

  test "rechaza cantidad cero y no crea el item" do
    cart = carts(:carrito_vacio)

    item = cart.add_product(products(:mouse), 0)

    assert_not item.persisted?
    assert_includes item.errors.attribute_names, :quantity
  end

  test "rechaza cantidad negativa y no crea el item" do
    cart = carts(:carrito_vacio)

    item = cart.add_product(products(:mouse), -2)

    assert_not item.persisted?
    assert_includes item.errors.attribute_names, :quantity
  end

  test "rechaza cantidad no entera y no crea el item" do
    cart = carts(:carrito_vacio)

    item = cart.add_product(products(:mouse), "1.5")

    assert_not item.persisted?
    assert_includes item.errors.attribute_names, :quantity
  end

  test "cantidad invalida sobre un producto ya en el carrito deja la cantidad original intacta" do
    cart = carts(:carrito_tienda)

    item = cart.add_product(products(:teclado), "1.5")

    assert_includes item.errors.attribute_names, :quantity
    assert_equal 2, cart_items(:teclado_en_carrito).reload.quantity
  end
end
