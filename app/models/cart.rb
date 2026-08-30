class Cart < ApplicationRecord
  belongs_to :store
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def empty?
    cart_items.empty?
  end

  # Si el producto ya está en el carrito, suma la cantidad en vez de crear un
  # segundo item (la constraint única es por cart_id + product_id).
  #
  # Se asigna `quantity` crudo y se valida antes de sumar porque la
  # validación numericality de Rails compara contra el valor antes del cast
  # (así "1.5" se rechaza aunque castee a 1). Sumar con `.to_i` a mano
  # perdería ese chequeo.
  def add_product(product, quantity)
    item = cart_items.find_or_initialize_by(product: product)
    previous_quantity = item.persisted? ? item.quantity : 0

    item.quantity = quantity
    item.valid?

    item.quantity = previous_quantity + item.quantity if item.errors[:quantity].empty?
    item.save
    item
  end
end
