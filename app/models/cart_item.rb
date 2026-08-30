class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :quantity, numericality: { less_than_or_equal_to: ->(item) { item.product&.stock } },
                        if: -> { product.present? }
  validates :product_id, uniqueness: { scope: :cart_id }

  # Precio vigente, no congelado: el carrito refleja el catálogo hasta que se
  # confirma la compra. El congelado ocurre recién en OrderItem.
  def unit_price_cents
    product.price_cents
  end

  def subtotal_cents
    quantity * unit_price_cents
  end
end
