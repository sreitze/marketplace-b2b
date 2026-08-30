class CreateSubOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :sub_orders do |t|
      t.references :order, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true

      t.timestamps
    end

    # Exactamente una suborden por proveedor dentro de una orden.
    add_index :sub_orders, [ :order_id, :supplier_id ], unique: true
  end
end
