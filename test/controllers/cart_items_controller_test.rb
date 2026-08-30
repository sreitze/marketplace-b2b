require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  test "agrega un producto al carrito y redirige al catalogo" do
    post cart_items_path, params: { product_id: products(:mouse).id, quantity: 2 }

    assert_redirected_to root_path
    cart = Cart.find(session[:cart_id])
    assert_equal 2, cart.cart_items.find_by(product: products(:mouse)).quantity
  end

  test "crear un item descuenta el stock del producto" do
    post cart_items_path, params: { product_id: products(:mouse).id, quantity: 2 }

    assert_equal 3, products(:mouse).reload.stock
  end

  test "cantidad mayor al stock disponible al crear no descuenta stock y muestra alert" do
    post cart_items_path, params: { product_id: products(:mouse).id, quantity: 6 }

    assert_redirected_to root_path
    assert_not_nil flash[:alert]
    assert_equal 5, products(:mouse).reload.stock
  end

  test "agregar el mismo producto dos veces suma cantidades" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 2 }

    cart = Cart.find(session[:cart_id])
    assert_equal 3, cart.cart_items.find_by(product: products(:teclado)).quantity
    assert_equal 1, cart.cart_items.where(product: products(:teclado)).count
  end

  test "cantidad invalida al agregar no crea el item y redirige con alert" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: "1.5" }

    assert_redirected_to root_path
    assert_not_nil flash[:alert]
    cart = Cart.find(session[:cart_id])
    assert_nil cart.cart_items.find_by(product: products(:teclado))
  end

  test "cantidad invalida no persiste cambios sobre un item ya existente" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 2 }

    post cart_items_path, params: { product_id: products(:teclado).id, quantity: "abc" }

    assert_redirected_to root_path
    cart = Cart.find(session[:cart_id])
    assert_equal 2, cart.cart_items.find_by(product: products(:teclado)).quantity
  end

  test "actualiza la cantidad de un item" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    item = Cart.find(session[:cart_id]).cart_items.find_by(product: products(:teclado))

    patch cart_item_path(item), params: { quantity: 5 }

    assert_redirected_to cart_path
    assert_equal 5, item.reload.quantity
  end

  test "actualizar con cantidad invalida no cambia nada y muestra alert" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    item = Cart.find(session[:cart_id]).cart_items.find_by(product: products(:teclado))

    patch cart_item_path(item), params: { quantity: 0 }

    assert_redirected_to cart_path
    assert_not_nil flash[:alert]
    assert_equal 1, item.reload.quantity
    assert_equal 7, products(:teclado).reload.stock
  end

  test "aumentar la cantidad de un item descuenta la diferencia del stock" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    item = Cart.find(session[:cart_id]).cart_items.find_by(product: products(:teclado))

    patch cart_item_path(item), params: { quantity: 5 }

    assert_equal 3, products(:teclado).reload.stock
  end

  test "reducir la cantidad de un item devuelve la diferencia al stock" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 5 }
    item = Cart.find(session[:cart_id]).cart_items.find_by(product: products(:teclado))

    patch cart_item_path(item), params: { quantity: 2 }

    assert_equal 6, products(:teclado).reload.stock
  end

  test "elimina un item del carrito" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    item = Cart.find(session[:cart_id]).cart_items.find_by(product: products(:teclado))

    delete cart_item_path(item)

    assert_redirected_to cart_path
    assert_not CartItem.exists?(item.id)
  end

  test "eliminar un item devuelve su cantidad al stock" do
    post cart_items_path, params: { product_id: products(:teclado).id, quantity: 1 }
    item = Cart.find(session[:cart_id]).cart_items.find_by(product: products(:teclado))

    delete cart_item_path(item)

    assert_equal 8, products(:teclado).reload.stock
  end

  test "no puede actualizar un item de un carrito distinto al de la sesión" do
    get cart_path # crea el carrito de la sesión actual, distinto al de la fixture

    patch cart_item_path(cart_items(:teclado_en_carrito)), params: { quantity: 5 }

    assert_response :not_found
    assert_equal 8, products(:teclado).reload.stock
  end
end
