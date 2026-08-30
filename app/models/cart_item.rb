class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :quantity, numericality: { less_than_or_equal_to: ->(item) { item.available_stock } },
                        if: -> { product.present? }
  validates :product_id, uniqueness: { scope: :cart_id }

  after_save :reserve_stock, if: :saved_change_to_quantity?
  after_destroy :release_stock

  # Precio vigente, no congelado: el carrito refleja el catálogo hasta que se
  # confirma la compra. El congelado ocurre recién en OrderItem.
  def unit_price_cents
    product.price_cents
  end

  def subtotal_cents
    quantity * unit_price_cents
  end

  # Tope real: lo que queda libre en el catálogo, más lo que esta misma fila
  # ya tiene reservado (y por lo tanto ya restó de product.stock).
  def available_stock
    product.stock + quantity_in_database.to_i
  end

  private

  # after_save/after_destroy corren dentro de la transacción implícita de
  # save/destroy: si product.update! falla, el cambio del cart item también
  # hace rollback. No hace falta un `transaction do` propio.
  def reserve_stock
    delta = quantity - quantity_before_last_save.to_i
    product.update!(stock: product.stock - delta)
  end

  def release_stock
    product.update!(stock: product.stock + quantity)
  end
end
