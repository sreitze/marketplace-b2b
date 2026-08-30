module Orders
  class CreateOrder
    class EmptyCartError < StandardError; end

    def self.call(cart:) = new(cart:).call

    def initialize(cart:) = @cart = cart

    def call
      raise EmptyCartError if cart.empty?

      order = nil
      ActiveRecord::Base.transaction do
        order = cart.store.orders.create!(total_cents: 0)

        order_total_cents = 0
        cart_items_by_supplier.each do |supplier, items|
          sub_order = order.sub_orders.create!(supplier: supplier, subtotal_cents: 0)
          subtotal_cents = 0
          items.each do |cart_item|
            order_item = sub_order.order_items.create!(
              product: cart_item.product,
              quantity: cart_item.quantity,
              unit_price_cents: cart_item.product.price_cents
            )
            subtotal_cents += order_item.subtotal_cents
          end
          sub_order.update!(subtotal_cents: subtotal_cents)
          order_total_cents += subtotal_cents
        end
        order.update!(total_cents: order_total_cents)

        # delete_all: DELETE directo por SQL, sin correr los callbacks de
        # CartItem. destroy_all dispararía release_stock y devolvería al
        # catálogo un stock que ya se convirtió en una orden real.
        cart.cart_items.delete_all
      end
      order
    end

    private

    attr_reader :cart

    def cart_items_by_supplier
      cart.cart_items.includes(product: :supplier).group_by { |item| item.product.supplier }
    end
  end
end
