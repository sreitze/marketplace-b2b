class Cart < ApplicationRecord
  belongs_to :store
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def empty?
    cart_items.empty?
  end
end
