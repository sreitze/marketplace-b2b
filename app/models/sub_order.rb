class SubOrder < ApplicationRecord
  belongs_to :order
  belongs_to :supplier
  has_many :order_items, dependent: :destroy

  validates :supplier_id, uniqueness: { scope: :order_id }
  validate :subtotal_reaches_supplier_minimum

  private

  # La regla cruza dos tablas (el subtotal de esta suborden contra el mínimo de
  # su proveedor), así que no se puede expresar como CHECK en la base.
  def subtotal_reaches_supplier_minimum
    puts "SUBTOTAL: " + subtotal_cents.to_s
    return if subtotal_cents.blank? || supplier.blank?
    return if subtotal_cents >= supplier.minimum_purchase_cents

    errors.add(:subtotal_cents, "no alcanza el mínimo de compra de #{supplier.name}")
  end
end
