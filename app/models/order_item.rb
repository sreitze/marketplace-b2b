class OrderItem < ApplicationRecord
  belongs_to :sub_order
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Usa unit_price_cents, congelado al confirmar la compra. Leer
  # product.price_cents acá haría que las órdenes históricas cambien de total
  # cuando el proveedor actualiza su catálogo.
  def subtotal_cents
    quantity * unit_price_cents
  end
end
