class SubOrder < ApplicationRecord
  belongs_to :order
  belongs_to :supplier
  has_many :order_items, dependent: :destroy

  validates :supplier_id, uniqueness: { scope: :order_id }
end
