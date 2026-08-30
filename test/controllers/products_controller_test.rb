require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "muestra los proveedores con sus productos" do
    get root_path

    assert_response :success
    assert_select "h2", text: suppliers(:acme).name
    assert_select "td", text: products(:teclado).name
  end

  test "no rompe si un proveedor todavía no tiene productos" do
    Supplier.create!(name: "Proveedor sin catálogo")

    get root_path

    assert_response :success
    assert_select "p", text: "Sin productos."
  end
end
