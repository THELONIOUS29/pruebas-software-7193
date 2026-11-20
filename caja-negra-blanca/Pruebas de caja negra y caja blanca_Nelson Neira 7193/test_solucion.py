import unittest

from solucion import aplicar_descuento, asignar_calificacion


class PruebasCajaNegraCalificaciones(unittest.TestCase):
    def test_promedio_mayor_a_90_devuelve_a(self):
        self.assertEqual(asignar_calificacion(95, 92, 94, 91), "A")

    def test_promedio_exactamente_90_devuelve_a(self):
        self.assertEqual(asignar_calificacion(90, 90, 90, 90), "A")

    def test_promedio_en_rango_b_devuelve_b(self):
        self.assertEqual(asignar_calificacion(80, 85, 82, 83), "B")

    def test_promedio_menor_a_90_pero_mayor_o_igual_a_80_devuelve_b(self):
        self.assertEqual(asignar_calificacion(90, 90, 90, 89), "B")

    def test_promedio_en_rango_c_devuelve_c(self):
        self.assertEqual(asignar_calificacion(70, 72, 75, 78), "C")

    def test_promedio_menor_a_80_pero_mayor_o_igual_a_70_devuelve_c(self):
        self.assertEqual(asignar_calificacion(80, 80, 80, 79), "C")

    def test_promedio_menor_a_70_devuelve_f(self):
        self.assertEqual(asignar_calificacion(60, 65, 68, 69), "F")

    def test_promedio_justo_debajo_de_70_devuelve_f(self):
        self.assertEqual(asignar_calificacion(70, 70, 70, 69), "F")


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
