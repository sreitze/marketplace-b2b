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
  ],
  "Initech Oficina" => [
    { name: "Resma de papel A4", price_cents: 4_500, stock: 50 },
    { name: "Archivador colgante", price_cents: 9_000, stock: 18 },
    { name: "Set de lapiceras", price_cents: 3_200, stock: 40 }
  ],
  "Umbrella Electrónica" => [
    { name: "Webcam HD", price_cents: 35_000, stock: 12 },
    { name: "Auriculares con micrófono", price_cents: 22_000, stock: 20 },
    { name: "Hub USB-C", price_cents: 18_000, stock: 15 }
  ],
  "Wayne Suministros" => [
    { name: "Impresora láser", price_cents: 310_000, stock: 3 },
    { name: "Cartucho de tóner", price_cents: 45_000, stock: 22 },
    { name: "Papel fotográfico", price_cents: 7_500, stock: 28 }
  ]
}.freeze

CATALOG.each do |supplier_name, products|
  supplier = Supplier.find_or_create_by!(name: supplier_name)

  products.each do |attrs|
    product = supplier.products.find_or_initialize_by(name: attrs[:name])
    product.update!(price_cents: attrs[:price_cents], stock: attrs[:stock])
  end
end
