class Store < ApplicationRecord
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true
end
