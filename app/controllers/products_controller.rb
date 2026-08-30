class ProductsController < ApplicationController
  def index
    @suppliers = Supplier.includes(:products).order(:name)
  end
end
