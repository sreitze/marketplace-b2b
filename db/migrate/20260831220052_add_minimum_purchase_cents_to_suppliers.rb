class AddMinimumPurchaseCentsToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :minimum_purchase_cents, :integer, null: false, default: 0
    add_check_constraint :suppliers, "minimum_purchase_cents >= 0",
                         name: "suppliers_minimum_purchase_cents_non_negative"
  end
end
