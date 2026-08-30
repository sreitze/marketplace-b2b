require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "es válido con proveedor, nombre, precio y stock" do
    assert products(:teclado).valid?
  end

  test "requiere nombre" do
    product = products(:teclado)
    product.name = ""

    assert_not product.valid?
    assert_includes product.errors.attribute_names, :name
  end

  test "requiere proveedor" do
    product = products(:teclado)
    product.supplier = nil

    assert_not product.valid?
    assert_includes product.errors.attribute_names, :supplier
  end

  test "rechaza precio negativo" do
    product = products(:teclado)
    product.price_cents = -1

    assert_not product.valid?
    assert_includes product.errors.attribute_names, :price_cents
  end

  test "rechaza stock negativo" do
    product = products(:teclado)
    product.stock = -1

    assert_not product.valid?
    assert_includes product.errors.attribute_names, :stock
  end

  test "pertenece a un único proveedor" do
    assert_equal suppliers(:acme), products(:teclado).supplier
    assert_equal suppliers(:globex), products(:monitor).supplier
  end

  test "actualizar el stock directamente sigue funcionando sin pasar por el carrito" do
    product = products(:mouse)

    product.update!(stock: 20)

    assert_equal 20, product.reload.stock
  end
end
