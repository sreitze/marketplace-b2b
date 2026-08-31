require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "es válido con nombre y mínimo de compra" do
    assert suppliers(:acme).valid?
  end

  test "requiere nombre" do
    supplier = suppliers(:acme)
    supplier.name = ""

    assert_not supplier.valid?
    assert_includes supplier.errors.attribute_names, :name
  end

  test "rechaza mínimo de compra negativo" do
    supplier = suppliers(:acme)
    supplier.minimum_purchase_cents = -1

    assert_not supplier.valid?
    assert_includes supplier.errors.attribute_names, :minimum_purchase_cents
  end

  test "rechaza mínimo de compra no entero" do
    supplier = suppliers(:acme)
    supplier.minimum_purchase_cents = "1.5"

    assert_not supplier.valid?
    assert_includes supplier.errors.attribute_names, :minimum_purchase_cents
  end

  test "el mínimo de compra arranca en cero" do
    assert_equal 0, Supplier.new.minimum_purchase_cents
  end
end
