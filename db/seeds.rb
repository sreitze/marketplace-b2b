# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Store.find_or_create_by!(name: "Tienda Central")

CATALOG = {
  "Acme Insumos" => [
    { name: "Teclado mecánico", price_cents: 15_000, stock: 10 },
    { name: "Mouse inalámbrico", price_cents: 8_000, stock: 25 },
    { name: "Monitor 24 pulgadas", price_cents: 90_000, stock: 4 }
  ],
  "Globex Tecnología" => [
    { name: "Silla ergonómica", price_cents: 120_000, stock: 6 },
    { name: "Escritorio ajustable", price_cents: 250_000, stock: 2 },
    { name: "Lámpara de escritorio", price_cents: 12_000, stock: 30 }
  ]
}.freeze

CATALOG.each do |supplier_name, products|
  supplier = Supplier.find_or_create_by!(name: supplier_name)

  products.each do |attrs|
    product = supplier.products.find_or_initialize_by(name: attrs[:name])
    product.update!(price_cents: attrs[:price_cents], stock: attrs[:stock])
  end
end
