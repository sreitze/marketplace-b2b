class Product < ApplicationRecord
  belongs_to :supplier
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
