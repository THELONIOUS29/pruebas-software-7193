import unittest
from matematica import Matematica

class TestMatematica(unittest.TestCase):

    # Pruebas base
    def test_mcd_entre_numeros(self):
        self.assertEqual(6, Matematica.mcd(54, 24))

    def test_mcd_con_un_numero_cero(self):
        self.assertEqual(10, Matematica.mcd(10, 0))

    def test_mcd_numeros_primos(self):
        self.assertEqual(1, Matematica.mcd(17, 13))

    # Pruebas adicionales
    def test_mcd_con_numeros_negativos(self):
        self.assertEqual(5, Matematica.mcd(-15, 10))

    def test_mcd_ambos_numeros_iguales(self):
        self.assertEqual(30, Matematica.mcd(30, 30))

    def test_mcd_numeros_grandes(self):
        self.assertEqual(500, Matematica.mcd(10000, 1500))

if __name__ == '__main__':
    unittest.main()
