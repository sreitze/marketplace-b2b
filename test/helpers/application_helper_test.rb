require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "formatea centavos como pesos con dos decimales" do
    assert_equal "$ 150,00", format_money(15_000)
  end

  test "rellena los centavos con cero a la izquierda" do
    assert_equal "$ 80,05", format_money(8_005)
  end

  test "formatea cero" do
    assert_equal "$ 0,00", format_money(0)
  end
end
