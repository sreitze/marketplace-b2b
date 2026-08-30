class Order < ApplicationRecord
  belongs_to :store
  has_many :sub_orders, dependent: :destroy
  has_many :order_items, through: :sub_orders
end
