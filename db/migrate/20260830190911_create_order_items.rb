class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :sub_order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      # Congelado al confirmar la compra: los totales históricos nunca se
      # recalculan leyendo products.price_cents.
      t.integer :unit_price_cents, null: false

      t.timestamps
    end

    add_index :order_items, [ :sub_order_id, :product_id ], unique: true
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
    add_check_constraint :order_items, "unit_price_cents >= 0", name: "order_items_unit_price_cents_non_negative"
  end
end
