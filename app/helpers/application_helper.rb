module ApplicationHelper
  # Formatea centavos en pesos sin pasar por floats, para no reintroducir el
  # problema de precisión que la columna *_cents ya evita en el dominio.
  def format_money(cents)
    pesos, centavos = cents.divmod(100)
    format("$ %d,%02d", pesos, centavos)
  end
end
