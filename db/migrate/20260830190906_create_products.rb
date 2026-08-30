class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :supplier, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price_cents, null: false
      t.integer :stock, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :products, "price_cents >= 0", name: "products_price_cents_non_negative"
    add_check_constraint :products, "stock >= 0", name: "products_stock_non_negative"
  end
end
