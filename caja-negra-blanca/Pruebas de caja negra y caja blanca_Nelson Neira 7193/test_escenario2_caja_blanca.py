import unittest

from solucion import aplicar_descuento


class PruebasCajaBlancaDescuento(unittest.TestCase):
    def test_ruta_sin_descuento_menor_a_100(self):
        self.assertEqual(aplicar_descuento(99.99), 99.99)

    def test_ruta_descuento_10_en_limite_inferior(self):
        self.assertEqual(aplicar_descuento(100), 90.0)

    def test_ruta_descuento_10_en_rango_medio(self):
        self.assertEqual(aplicar_descuento(150), 135.0)

    def test_ruta_descuento_10_justo_debajo_de_200(self):
        self.assertEqual(aplicar_descuento(199.99), 179.991)

    def test_ruta_descuento_20_en_limite_inferior(self):
        self.assertEqual(aplicar_descuento(200), 160.0)

    def test_ruta_descuento_20_en_valor_superior(self):
        self.assertEqual(aplicar_descuento(350), 280.0)


if __name__ == "__main__":
    unittest.main()
