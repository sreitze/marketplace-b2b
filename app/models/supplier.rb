class Supplier < ApplicationRecord
  has_many :products, dependent: :restrict_with_error
  has_many :sub_orders, dependent: :restrict_with_error

  validates :name, presence: true
end
