class AddTotalCentsToOrdersAndSubOrders < ActiveRecord::Migration[8.1]
  def up
    add_column :sub_orders, :subtotal_cents, :integer
    SubOrder.reset_column_information
    SubOrder.find_each do |sub_order|
      sub_order.update_column(:subtotal_cents, sub_order.order_items.sum { |i| i.quantity * i.unit_price_cents })
    end
    change_column_null :sub_orders, :subtotal_cents, false
    add_check_constraint :sub_orders, "subtotal_cents >= 0", name: "sub_orders_subtotal_cents_non_negative"

    add_column :orders, :total_cents, :integer
    Order.reset_column_information
    Order.find_each do |order|
      order.update_column(:total_cents, order.sub_orders.sum(&:subtotal_cents))
    end
    change_column_null :orders, :total_cents, false
    add_check_constraint :orders, "total_cents >= 0", name: "orders_total_cents_non_negative"
  end

  def down
    remove_check_constraint :orders, name: "orders_total_cents_non_negative"
    remove_column :orders, :total_cents
    remove_check_constraint :sub_orders, name: "sub_orders_subtotal_cents_non_negative"
    remove_column :sub_orders, :subtotal_cents
  end
end
